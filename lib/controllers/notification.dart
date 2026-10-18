import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/main.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:xdg_desktop_portal/xdg_desktop_portal.dart";

class NotificationController
    extends AsyncNotifier<FlutterLocalNotificationsPlugin> {
  @override
  Future<FlutterLocalNotificationsPlugin> build() async {
    final notifications = FlutterLocalNotificationsPlugin();

    if (!Platform.isLinux) {
      final darwin = DarwinInitializationSettings();

      await notifications.initialize(
        settings: .new(
          windows: .new(
            appName: "Nexus",
            appUserModelId: "nexus.federated.nexus",
            guid: "dde78daf-130f-4e46-a80a-e31deeab45d7",
          ),
          android: .new("ic_launcher_foreground"),
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (details) {
          if (details.payload == null) return;

          if (int.tryParse(details.payload!) case final rowId?) {
            navigatorKey.currentState?.popUntil((route) => route.isFirst);
            ref
                .read(SidebarPageController.provider.notifier)
                .set(.notifications);
            ref
                .read(NotificationRequestController.provider.notifier)
                .request(rowId);
          }
        },
      );
    }

    if (Platform.isLinux) {
      const notificationChannel = MethodChannel("nexus/notifications");

      notificationChannel.setMethodCallHandler((call) async {
        if (call.method != "notificationClicked") {
          return;
        }

        if (int.tryParse(call.arguments) case int rowId) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
          ref.read(SidebarPageController.provider.notifier).set(.notifications);
          ref
              .read(NotificationRequestController.provider.notifier)
              .request(rowId);
        }
      });

      ref.onDispose(() => notificationChannel.setMethodCallHandler(null));
    }

    return notifications;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isLinux) {
      return true;
    }

    final controller = await future;

    if (Platform.isIOS) {
      return await controller
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    } else if (Platform.isMacOS) {
      return await controller
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    } else if (Platform.isAndroid) {
      return await controller
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }

    return true;
  }

  /// Whether notifications can currently be shown, without prompting
  Future<bool> permissionsGranted() async {
    if (Platform.isLinux) {
      return true;
    }

    final controller = await future;

    if (Platform.isIOS) {
      return (await controller
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled ??
          true;
    } else if (Platform.isMacOS) {
      return (await controller
                  .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin
                  >()
                  ?.checkPermissions())
              ?.isEnabled ??
          true;
    } else if (Platform.isAndroid) {
      return await controller
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          true;
    }

    return true;
  }

  Future<void> send({
    required int id,
    required String title,
    String? body,
    File? icon,
    String? payload,
    String? senderName,
    File? senderAvatar,
    String? selfName,
    bool isGroup = false,
    bool sound = true,
    DateTime? timestamp,
    String? threadId,
  }) async {
    debugPrint("Sending notification for $id");

    // In DMs the title is already the sender, so only prefix in groups
    final prefix = isGroup ? senderName : null;

    if (Platform.isLinux) {
      final portal = await ref.read(PortalController.provider.future);
      const escape = HtmlEscape(HtmlEscapeMode.element);

      await portal.notification.addNotification(
        id.toString(),
        title: title,
        body: prefix == null || body == null ? body : "$prefix: $body",
        markupBody: prefix == null || body == null
            ? null
            : "<b>${escape.convert(prefix)}</b>: ${escape.convert(body)}",
        defaultAction: "app.event",
        defaultActionTarget: payload,
        sound: sound ? null : const XdgNotificationSoundSilent(),
        category: XdgNotificationCategory.imReceived,
        priority: .normal,
        buttons: [
          // TODO: Impl when notif daemons actualy support imReplyWithText
          // .new(
          //   label: "Reply",
          //   action: "app.reply",
          //   purpose: XdgNotificationButtonPurpose.imReplyWithText,
          // ),
        ],
      );
    } else {
      final controller = await future;

      // Append to the conversation already shown under this id, if any
      final existingStyle = Platform.isAndroid
          ? await controller
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.getActiveNotificationMessagingStyle(id: id)
                .onError((_, _) => null)
          : null;

      final darwin = DarwinNotificationDetails(
        presentSound: sound,
        threadIdentifier: threadId,
      );
      final notificationDetails = NotificationDetails(
        android: .new(
          "messages",
          "Messages",
          silent: !sound,
          largeIcon: icon == null ? null : FilePathAndroidBitmap(icon.path),
          styleInformation: senderName == null || body == null
              ? null
              : MessagingStyleInformation(
                  .new(name: selfName ?? "You"),
                  conversationTitle: isGroup ? title : null,
                  groupConversation: isGroup,
                  messages: [
                    ...?existingStyle?.messages,
                    .new(
                      body,
                      timestamp ?? .now(),
                      .new(
                        name: senderName,
                        icon: senderAvatar == null
                            ? null
                            : BitmapFilePathAndroidIcon(senderAvatar.path),
                      ),
                    ),
                  ],
                ),
        ),
        iOS: darwin,
        macOS: darwin,
        windows: .new(
          audio: sound ? null : .silent(),
          timestamp: timestamp,
          header: threadId == null
              ? null
              : .new(id: threadId, title: title, arguments: payload ?? ""),
        ),
      );

      await controller.show(
        id: id,
        title: title,
        body: prefix == null || body == null ? body : "$prefix: $body",
        notificationDetails: notificationDetails,
        payload: payload,
      );
    }
  }

  static final provider =
      AsyncNotifierProvider<
        NotificationController,
        FlutterLocalNotificationsPlugin
      >(NotificationController.new);
}
