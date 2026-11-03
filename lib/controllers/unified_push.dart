import "dart:async";
import "dart:convert";
import "dart:io";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/accounts.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/selected_room.dart";
import "package:nexus/controllers/notification.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/push_key.dart";
import "package:nexus/main.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/gomuks_listener.dart";
import "package:unifiedpush/unifiedpush.dart";
import "package:unifiedpush_storage_shared_preferences/storage.dart";
import "package:window_manager/window_manager.dart";

class UnifiedPushController extends AsyncNotifier<String?> {
  Completer<void>? _endpoint;

  /// The account [instance] (its device ID) belongs to, or the active one for
  /// devices registered before account switching.
  Future<String> _accountFor(String instance) async =>
      (await ref.read(AccountsController.provider.future))
          .firstWhereOrNull((account) => account.deviceId == instance)
          ?.id ??
      ref.read(ActiveAccountController.provider);

  ClientController _clientFor(String accountId) =>
      accountId == ref.read(ActiveAccountController.provider)
      ? ref.read(ClientController.provider.notifier)
      : ref.read(ClientController.forAccount(accountId).notifier);

  @override
  Future<String?> build() async {
    if (!Platform.isLinux && !Platform.isAndroid) return null;

    final registered = await UnifiedPush.initialize(
      linuxOptions: .new(
        dbusName: "nexus.federated.nexus.UnifiedPush",
        storage: UnifiedPushStorageSharedPreferences(),
        background: isInBackground,
        shouldWriteService: false,
      ),
      onNewEndpoint: (endpoint, instance) async {
        final task = Future(() async {
          final pushKey = endpoint.pubKeySet!.pubKey;
          await ref
              .read(PushKeyController.provider(instance).notifier)
              .set(pushKey);

          await _clientFor(await _accountFor(instance)).registerPusher(
            .new(
              appDisplayName: "Nexus",
              appId: "nexus.federated.nexus",
              data: .webPush(
                url: .parse(endpoint.url),
                auth: endpoint.pubKeySet!.auth,
              ),
              deviceDisplayName:
                  "Nexus on ${toBeginningOfSentenceCase(Platform.operatingSystem)}",
              kind: .webPush,
              lang: "en",
              pushKey: pushKey,
            ),
          );

          state = .data(await UnifiedPush.getDistributor());
        });

        if (_endpoint case final completer? when !completer.isCompleted) {
          completer.complete(task);
        } else {
          await task;
        }
      },
      onRegistrationFailed: (reason, instance) {
        if (_endpoint case final completer? when !completer.isCompleted) {
          completer.completeError(reason);
        } else {
          throw reason;
        }
      },
      onMessage: (message, instance) async {
        debugPrint("UP message received for $instance");
        if (await deregisterIfDisabled(instance)) {
          if (isInBackground) exit(0);
          return;
        }

        if (message.decrypted == false) {
          throw Exception(
            "Failed to decrypt notification. Try toggling off and on UnifiedPush in settings.",
          );
        }
        final accountId = await _accountFor(instance);
        final client = _clientFor(accountId);
        final isActive =
            accountId == ref.read(ActiveAccountController.provider);
        final notification = await client.handlePush(
          json.decode(String.fromCharCodes(message.content)),
        );

        if (notification == null ||
            (!isInBackground &&
                isActive &&
                (WindowManager.instance.getCurrent()?.isFocused ?? false) &&
                ref.read(SelectedRoomController.provider) ==
                    notification.roomId)) {
          if (isInBackground) exit(0);
          return;
        }

        final hasOtherAccounts =
            (await ref.read(AccountsController.provider.future)).length > 1;

        final icon = notification.roomAvatar == null
            ? null
            : await client.downloadMedia(
                .new(mxc: notification.roomAvatar!, isAvatar: true),
              );

        final pmp = notification.perMessageProfile;
        final senderAvatarUrl = pmp?.avatar ?? notification.sender.avatar;
        // Only Android can show the sender's avatar
        final senderAvatar = senderAvatarUrl == null || !Platform.isAndroid
            ? null
            : await client.downloadMedia(
                .new(mxc: senderAvatarUrl, isAvatar: true),
              );

        await ref
            .read(NotificationController.provider.notifier)
            .send(
              // Android stacks messages into one conversation per room (and
              // account, since two accounts can share a room)
              id:
                  "$accountId/${Platform.isAndroid ? notification.roomId : notification.eventId}"
                      .hashCode &
                  0x7fffffff,
              threadId: "$accountId/${notification.roomId}",
              title: notification.roomName,
              subtitle: hasOtherAccounts ? notification.self.id : null,
              body: notification.text,
              payload: NotificationController.payloadFor(
                accountId,
                notification.eventRowId,
              ),
              timestamp: notification.timestamp,
              icon: icon,
              sound: notification.sound,
              message: (
                sender: pmp == null
                    ? notification.sender
                    : pmp.copyWith(id: "${notification.sender.id}/${pmp.id}"),
                self: notification.self,
                senderAvatar: senderAvatar,
                isDm: notification.isDm,
              ),
            );

        if (isInBackground) exit(0);
      },
      onUnregistered: deregister,
    );

    if (!registered || isInBackground) return null;

    ref.listen(
      ClientStateController.provider.select((state) => state?.isLoggedIn),
      (previous, isLoggedIn) => Future(() async {
        if (isLoggedIn != true) return;
        if (await deregisterIfDisabled()) return;

        // On startup, only accounts with push on (which have a push key).
        // After logging in, push is on by default.
        final deviceId = ref.read(ClientStateController.provider)?.deviceId;
        if (previous != false &&
            (deviceId == null ||
                await ref.read(PushKeyController.provider(deviceId).future) ==
                    null)) {
          return;
        }

        try {
          await register();
        } on UnsupportedError {
          // The settings tile explains that the homeserver can't send Web Push
        }
      }).catchError(showError),
      fireImmediately: true,
    );

    return null;
  }

  /// Registers with [distributor], or the current/default distributor if none
  /// is given. Returns the distributor that was registered with.
  Future<String?> register([String? distributor]) async {
    if (distributor != null &&
        state.value != null &&
        state.value != distributor) {
      await deregister();
    }

    // Not loading until logged in, since the app waits for this
    final deviceId = await ref
        .read(GomuksListenerController.provider.notifier)
        .deviceId();

    state = .loading();
    try {
      await Future(() async {
        final capabilities = await ref
            .read(ClientController.provider.notifier)
            .getCapabilities();

        if (capabilities.webpush?.vapid == null) {
          throw UnsupportedError(
            "Your homeserver does not support MSC4174 (Web Push), and therefore cannot send notifications to Nexus.",
          );
        }

        if (distributor != null) {
          await UnifiedPush.saveDistributor(distributor);
        } else if (!await UnifiedPush.tryUseCurrentOrDefaultDistributor()) {
          throw Exception("No UnifiedPush distributors found.");
        }

        final endpoint = _endpoint = Completer<void>();

        try {
          await Future.wait([
            UnifiedPush.register(
              instance: deviceId,
              vapid: capabilities.webpush?.vapid,
            ),
            endpoint.future,
          ], eagerError: true);
        } finally {
          if (_endpoint == endpoint) _endpoint = null;
        }
      }).timeout(
        .new(seconds: 10),
        onTimeout: () => throw Exception("UnifiedPush registration timed out."),
      );

      final current = await UnifiedPush.getDistributor();
      state = .data(current);
      return current;
    } catch (_) {
      state = .data(null);
      rethrow;
    }
  }

  Future<bool> deregisterIfDisabled([String? notificationInstance]) async {
    if (await ref
        .read(NotificationController.provider.notifier)
        .permissionsGranted()) {
      return false;
    }

    final instance =
        notificationInstance ??
        await ref.read(GomuksListenerController.provider.notifier).deviceId();
    final key = await ref.read(PushKeyController.provider(instance).future);
    if (key != null) await deregister(instance);
    return true;
  }

  Future<void> deregister([String? instance]) async {
    instance ??= await ref
        .read(GomuksListenerController.provider.notifier)
        .deviceId();

    final keyProvider = PushKeyController.provider(instance);
    final key = await ref.read(keyProvider.future);
    final accountId = await _accountFor(instance);

    if (key != null) {
      await _clientFor(accountId)
          .deregisterPusher(.new(appId: "nexus.federated.nexus", pushKey: key));
      await ref.read(keyProvider.notifier).set(null);
    } else {
      debugPrint(
        "No matching pushKey found. Skipping deregistration from homeserver.",
      );
    }

    await UnifiedPush.unregister(instance);
    if (accountId == ref.read(ActiveAccountController.provider)) {
      state = .data(null);
    }
  }

  static final provider = AsyncNotifierProvider<UnifiedPushController, String?>(
    UnifiedPushController.new,
  );
}
