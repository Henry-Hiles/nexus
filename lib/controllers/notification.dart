import "dart:io";

import "package:material_ui/material_ui.dart";
import "package:nexus/main.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
// ignore: implementation_imports
import "package:flutter_local_notifications_linux/src/model/hint.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/pages/notifications.dart";

class NotificationController
    extends AsyncNotifier<FlutterLocalNotificationsPlugin> {
  @override
  Future<FlutterLocalNotificationsPlugin> build() async {
    final notifications = FlutterLocalNotificationsPlugin();

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
        linux: .new(defaultActionName: "Open"),
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload case final eventId?) {
          if (navigatorKey.currentContext case final context?) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsPage(eventId: eventId),
              ),
            );
          }
        }
      },
    );

    return notifications;
  }

  Future<bool> requestPermissions() async {
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
    final notificationDetails = NotificationDetails(
      android: .new(
        "messages",
        "Messages",
        largeIcon: icon == null ? null : FilePathAndroidBitmap(icon.path),
      ),
      linux: .new(
        customHints: icon == null
            ? null
            : [
                .new(
                  name: "image-path",
                  value: LinuxHintStringValue(icon.path),
                ),
              ],
      ),
      // TODO: See if icons can be added to iOS, macOS, and Windows notifications (#68)
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

  static final provider =
      AsyncNotifierProvider<
        NotificationController,
        FlutterLocalNotificationsPlugin
      >(NotificationController.new);
}
