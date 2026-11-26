import "dart:async";
import "dart:convert";
import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/launch_scope.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/helpers/shown_notifications_helper.dart";
import "package:nexus/main.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/push_notification.dart";
import "package:xdg_desktop_portal/xdg_desktop_portal.dart";

typedef NotificationMessage = ({
  NotificationUser sender,
  NotificationUser self,
  File? senderAvatar,
  bool isDm,
});

class NotificationController
    extends AsyncNotifier<FlutterLocalNotificationsPlugin> {
  @override
  Future<FlutterLocalNotificationsPlugin> build() async {
    final notifications = FlutterLocalNotificationsPlugin();

    if (Platform.isLinux) {
      const MethodChannel("nexus/notifications")
          .setMethodCallHandler((call) async {
            if (call case MethodCall(
              method: "notificationClicked",
              arguments: final String payload,
            )) {
              _open(payload);
            }
          });
    } else {
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
          if (details.payload case final payload?) _open(payload);
        },
      );

      await notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.deleteNotificationChannel(channelId: "messages");

      // Taps that launched the app don't reach the callback above
      if (!isInBackground && ref.read(LaunchScopeController.provider)) {
        if (await notifications.getNotificationAppLaunchDetails()
            case NotificationAppLaunchDetails(
              didNotificationLaunchApp: true,
              notificationResponse: NotificationResponse(:final payload?),
            )) {
          _open(payload);
        }
      }
    }

    // Reading a room, here or on another client, dismisses its notifications
    if (!isInBackground) {
      ref.listen(
        RoomsController.provider.select(
          (rooms) => rooms
              .where((_, room) => room.metadata?.unreadNotifications == 0)
              .keys
              .toISet(),
        ),
        (previous, read) {
          final newlyRead = read.difference(previous ?? const ISetConst({}));
          if (newlyRead.isEmpty) return;

          final accountId = ref.read(ActiveAccountController.provider);
          dismiss(
            newlyRead.map((roomId) => threadIdFor(accountId, roomId)).toISet(),
          ).onError(showError);
        },
        fireImmediately: true,
      );
    }

    return notifications;
  }

  static String threadIdFor(String accountId, String roomId) =>
      "$accountId/$roomId";

  static String payloadFor(String accountId, int rowId) => "$accountId:$rowId";

  static const _messagesChannel = "messages_v2";
  static const _androidGroup = "nexus.federated.nexus.MESSAGES";

  /// Dismisses the notifications shown for [threadIds].
  Future<void> dismiss(ISet<String> threadIds) async {
    final ids = await ref
        .read(ShownNotificationsHelper.provider)
        .remove(threadIds);
    if (ids.isEmpty) return;

    if (Platform.isLinux) {
      final portal = await ref.read(PortalController.provider.future);
      await Future.wait(
        ids.map((id) => portal.notification.removeNotification(id.toString())),
      );
      return;
    }

    final controller = await future;
    await Future.wait(ids.map((id) => controller.cancel(id: id)));

    // The summary would otherwise outlive its group
    if (Platform.isAndroid &&
        (await controller.getActiveNotifications()).every(
          (notification) => notification.id == 0,
        )) {
      await controller.cancel(id: 0);
    }
  }

  void _open(String payload) {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    ref.read(SidebarPageController.provider.notifier).set(.notifications);

    final (accountId, rowId) = switch (payload.split(":")) {
      [final accountId, final rowId] => (accountId, int.tryParse(rowId)),
      // From before notifications were per account
      [final rowId] => (null, int.tryParse(rowId)),
      _ => (null, null),
    };
    if (rowId == null) return;

    ref
        .read(ActiveAccountController.provider.notifier)
        .switchTo(
          accountId ?? ref.read(ActiveAccountController.provider),
          notificationRowId: rowId,
        )
        .onError(showError);
  }

  // Each resolves to null except on its own platform
  Future<bool> requestPermissions() async {
    final controller = await future;

    return await controller
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        await controller
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        await controller
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
  }

  /// Whether notifications can currently be shown, without prompting
  Future<bool> permissionsGranted() async {
    final controller = await future;

    return (await controller
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.checkPermissions())
            ?.isEnabled ??
        (await controller
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.checkPermissions())
            ?.isEnabled ??
        await controller
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled() ??
        true;
  }

  /// Passing [message] shows it as a chat message in the conversation for
  /// [threadId], naming the sender in group chats. [subtitle] is shown on
  /// platforms that support it.
  Future<void> send({
    required int id,
    required String title,
    String? subtitle,
    required String body,
    String? payload,
    String? threadId,
    DateTime? timestamp,
    File? icon,
    bool sound = true,
    NotificationMessage? message,
  }) async {
    debugPrint("Sending notification for $id");

    // In DMs the title is already the sender
    final sender = message == null || message.isDm ? null : message.sender;
    final prefixedBody = sender == null ? body : "${sender.name}: $body";
    final shown = ref.read(ShownNotificationsHelper.provider);

    if (Platform.isLinux) {
      final portal = await ref.read(PortalController.provider.future);
      const escape = HtmlEscape(.element);

      await portal.notification.addNotification(
        id.toString(),
        title: title,
        body: prefixedBody,
        markupBody: sender == null
            ? null
            : "<b>${escape.convert(sender.name)}</b>: ${escape.convert(body)}",
        defaultAction: "app.event",
        defaultActionTarget: payload,
        sound: sound ? null : const XdgNotificationSoundSilent(),
        category: message == null ? null : XdgNotificationCategory.imReceived,
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
      if (threadId != null) await shown.add(threadId, id);
      return;
    }

    final controller = await future;

    // Append to the conversation already shown under this id, if any
    final existingStyle = Platform.isAndroid && message != null
        ? await controller
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.getActiveNotificationMessagingStyle(id: id)
              .onError((_, _) => null)
        : null;

    final largeIcon = icon == null ? null : FilePathAndroidBitmap(icon.path);
    final darwin = DarwinNotificationDetails(
      subtitle: subtitle,
      presentSound: sound,
      threadIdentifier: threadId,
    );

    await controller.show(
      id: id,
      title: title,
      body: prefixedBody,
      payload: payload,
      notificationDetails: .new(
        android: message == null
            ? .new(
                "general",
                "General",
                groupKey: _androidGroup,
                subText: subtitle,
                silent: !sound,
                when: timestamp?.millisecondsSinceEpoch,
                largeIcon: largeIcon,
                styleInformation: BigTextStyleInformation(body),
              )
            : .new(
                _messagesChannel,
                "Messages",
                importance: .high,
                priority: .high,
                groupKey: _androidGroup,
                subText: subtitle,
                silent: !sound,
                when: timestamp?.millisecondsSinceEpoch,
                category: .message,
                largeIcon: largeIcon,
                styleInformation: MessagingStyleInformation(
                  .new(key: message.self.id, name: message.self.name),
                  conversationTitle: message.isDm ? null : title,
                  groupConversation: !message.isDm,
                  messages: [
                    ...?existingStyle?.messages,
                    .new(
                      body,
                      timestamp ?? .now(),
                      .new(
                        key: message.sender.id,
                        name: message.sender.name,
                        icon: switch (message.senderAvatar) {
                          final avatar? => BitmapFilePathAndroidIcon(
                            avatar.path,
                          ),
                          null => null,
                        },
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
      ),
    );

    if (threadId != null) await shown.add(threadId, id);

    if (Platform.isAndroid) {
      await controller.show(
        id: 0,
        title: "Nexus",
        payload: payload,
        notificationDetails: const .new(
          android: .new(
            _messagesChannel,
            "Messages",
            importance: .high,
            groupKey: _androidGroup,
            setAsGroupSummary: true,
            groupAlertBehavior: .children,
            onlyAlertOnce: true,
            silent: true,
          ),
        ),
      );
    }
  }

  static final provider =
      AsyncNotifierProvider<
        NotificationController,
        FlutterLocalNotificationsPlugin
      >(NotificationController.new);
}
