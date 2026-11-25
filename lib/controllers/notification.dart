import "dart:async";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/portal.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/shared_prefs.dart";
import "package:nexus/controllers/sidebar_page.dart";
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
          if (details.payload case final payload?) _open(payload);
        },
      );

      await notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.deleteNotificationChannel(channelId: "messages");
    }

    if (Platform.isLinux) {
      const notificationChannel = MethodChannel("nexus/notifications");

      notificationChannel.setMethodCallHandler((call) async {
        if (call.method != "notificationClicked") {
          return;
        }

        if (call.arguments case final String payload) _open(payload);
      });
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
          dismiss(newlyRead.map((roomId) => threadIdFor(accountId, roomId)))
              .onError(showError);
        },
        fireImmediately: true,
      );
    }

    return notifications;
  }

  static String threadIdFor(String accountId, String roomId) =>
      "$accountId/$roomId";

  static String payloadFor(String accountId, int rowId) => "$accountId:$rowId";

  static const _androidGroup = "nexus.federated.nexus.MESSAGES";
  static const _summaryPayload = "summary";

  static const _messagesChannel = "messages_v2";
  static const _shownKey = "shownNotifications";

  /// IDs of the notifications shown, by thread. Stored, since they're often
  /// shown by a background instance.
  Future<IMap<String, IList<int>>> _shown() async => IMap<String, dynamic>(
    json.decode(
      await ref.read(SharedPrefsController.provider).getString(_shownKey) ??
          "{}",
    ),
  ).map((threadId, ids) => .new(threadId, IList((ids as List).cast<int>())));

  Future<void> _setShown(IMap<String, IList<int>> shown) => ref
      .read(SharedPrefsController.provider)
      .setString(
        _shownKey,
        json.encode(
          shown.map((threadId, ids) => .new(threadId, ids.unlock)).unlock,
        ),
      );

  Future<void> _track(String threadId, int id) async {
    final shown = await _shown();
    final ids = shown[threadId] ?? const IListConst([]);
    if (!ids.contains(id)) await _setShown(shown.add(threadId, ids.add(id)));
  }

  /// Dismisses the notifications shown for [threadIds].
  Future<void> dismiss(Iterable<String> threadIds) async {
    final shown = await _shown();
    final ids = threadIds.map((threadId) => shown[threadId]).nonNulls.flattened;
    if (ids.isEmpty) return;

    await _setShown(
      shown.removeWhere((threadId, _) => threadIds.contains(threadId)),
    );

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
    if (payload == _summaryPayload) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      ref.read(SidebarPageController.provider.notifier).set(.notifications);
      return;
    }

    final (accountId, rowId) = switch (payload.split(":")) {
      [final accountId, final rowId] => (accountId, int.tryParse(rowId)),
      // From before notifications were per account
      [final rowId] => (null, int.tryParse(rowId)),
      _ => (null, null),
    };
    if (rowId == null) return;

    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    ref.read(SidebarPageController.provider.notifier).set(.notifications);

    ref
        .read(ActiveAccountController.provider.notifier)
        .switchTo(
          accountId ?? ref.read(ActiveAccountController.provider),
          notificationRowId: rowId,
        )
        .onError(showError);
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
      if (threadId != null) await _track(threadId, id);
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
                largeIcon: icon == null
                    ? null
                    : FilePathAndroidBitmap(icon.path),
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
                largeIcon: icon == null
                    ? null
                    : FilePathAndroidBitmap(icon.path),
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
                        icon: message.senderAvatar == null
                            ? null
                            : BitmapFilePathAndroidIcon(
                                message.senderAvatar!.path,
                              ),
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

    if (threadId != null) await _track(threadId, id);

    if (Platform.isAndroid) {
      await controller.show(
        id: 0,
        title: "Nexus",
        payload: _summaryPayload,
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
