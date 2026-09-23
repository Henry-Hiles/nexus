import "dart:async";
import "dart:io";

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/main.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/pages/notifications.dart";
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
          if (details.payload case final eventId?) {
            if (navigatorKey.currentContext case final context?) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsPage(
                    highlightedEventId: eventId,
                    defaultToAllNotifications: true,
                  ),
                ),
              );
            }
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

        final eventId = call.arguments as String;

        if (navigatorKey.currentContext case final context?) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationsPage(
                highlightedEventId: eventId,
                defaultToAllNotifications: true,
              ),
            ),
          );
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

  Future<void> send({
    required int id,
    required String title,
    String? body,
    File? icon,
    String? payload,
  }) async {
    debugPrint("Sending notification for $id");

    if (Platform.isLinux) {
      final portal = await ref.watch(PortalController.provider.future);

      await portal.notification.addNotification(
        id.toString(),
        title: title,
        body: body,
        icon: icon == null ? null : XdgNotificationIconFile(icon.path),
        defaultAction: "app.event",
        defaultActionTarget: payload,
      );
    } else {
      final notificationDetails = NotificationDetails(
        android: .new(
          "messages",
          "Messages",
          largeIcon: icon == null ? null : FilePathAndroidBitmap(icon.path),
        ),
        // TODO: See if icons can be added to iOS, macOS, and Windows
        // notifications (#68)
        iOS: .new(),
        macOS: .new(),
        windows: .new(),
      );

      final controller = await future;

      await controller.show(
        id: id,
        title: title,
        body: body,
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
