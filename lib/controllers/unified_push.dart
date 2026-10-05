import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/notification.dart";
import "package:nexus/controllers/push_key.dart";
import "package:nexus/main.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/sticker.dart";
import "package:unifiedpush/unifiedpush.dart";
import "package:unifiedpush_storage_shared_preferences/storage.dart";
import "package:window_manager/window_manager.dart";

class UnifiedPushController extends AsyncNotifier<bool> {
  Completer<void>? _endpoint;

  @override
  Future<bool> build() async {
    if (!Platform.isLinux && !Platform.isAndroid) return false;

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

          await ref
              .read(ClientController.provider.notifier)
              .registerPusher(
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

          state = .data(true);
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
        if (message.decrypted == false) {
          throw Exception(
            "Failed to decrypt notification. Try toggling off and on UnifiedPush in settings.",
          );
        }
        final pushResponse = await ref
            .read(ClientController.provider.notifier)
            .handlePush(json.decode(String.fromCharCodes(message.content)));

        if (pushResponse == null) return;

        final (event, roomMetadata) = pushResponse;

        if (event.unreadType?.shouldNotify() != true ||
            (!isInBackground &&
                await windowManager.isFocused().onError((_, _) => true) &&
                await ref.read(
                      KeyController.provider(KeyController.roomKey).future,
                    ) ==
                    event.roomId)) {
          if (isInBackground) exit(0);
          return;
        }

        final icon = roomMetadata.avatar == null
            ? null
            : await ref
                  .read(ClientController.provider.notifier)
                  .downloadMedia(
                    .new(mxc: roomMetadata.avatar!, isAvatar: true),
                  );

        await ref
            .read(NotificationController.provider.notifier)
            .send(
              id: event.eventId.hashCode & 0x7fffffff,
              title: roomMetadata.name ?? "New Event",
              icon: icon,
              payload: event.rowId.toString(),
              body: switch (event.content) {
                MessageContent(:final body?) ||
                StickerContent(:final body) => body,
                _ => null,
              },
            );

        if (isInBackground) exit(0);
      },
      onUnregistered: deregister,
    );

    if (!registered) return false;

    try {
      return await register();
    } catch (error, stackTrace) {
      showError(error, stackTrace);
      return false;
    }
  }

  Future<bool> register() async {
    state = .loading();
    try {
      final deviceIdCompleter = Completer<String>();
      final subscription = ref.listen(
        ClientStateController.provider.select((value) => value?.deviceId),
        (_, next) {
          if (next != null && !deviceIdCompleter.isCompleted) {
            deviceIdCompleter.complete(next);
          }
        },
        fireImmediately: true,
      );
      final deviceId = await deviceIdCompleter.future.whenComplete(
        subscription.close,
      );

      await Future(() async {
        final capabilities = await ref
            .read(ClientController.provider.notifier)
            .getCapabilities();

        if (capabilities.webpush?.vapid == null) {
          throw UnsupportedError(
            "Your homeserver does not support MSC4174 (Web Push), and therefore cannot send notifications to Nexus.",
          );
        }

        if (!await UnifiedPush.tryUseCurrentOrDefaultDistributor()) {
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

      state = .data(true);
      return true;
    } catch (_) {
      state = .data(false);
      rethrow;
    }
  }

  Future<void> deregister([String? instance]) async {
    final clientState = ref.read(ClientStateController.provider);

    final keyProvider = PushKeyController.provider(
      instance ?? clientState!.deviceId!,
    );
    final key = await ref.read(keyProvider.future);

    if (key != null) {
      await ref
          .read(ClientController.provider.notifier)
          .deregisterPusher(.new(appId: "nexus.federated.nexus", pushKey: key));
      await ref.read(keyProvider.notifier).set(null);
    } else {
      debugPrint(
        "No matching pushKey found. Skipping deregistration from homeserver.",
      );
    }

    await UnifiedPush.unregister(instance ?? clientState!.deviceId!);
    state = .data(false);
  }

  static final provider = AsyncNotifierProvider<UnifiedPushController, bool>(
    UnifiedPushController.new,
  );
}
