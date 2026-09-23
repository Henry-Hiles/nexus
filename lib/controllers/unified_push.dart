import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/notification.dart";
import "package:nexus/controllers/push_key.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/main.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/sticker.dart";
import "package:unifiedpush/unifiedpush.dart";
import "package:unifiedpush_storage_shared_preferences/storage.dart";
import "package:window_manager/window_manager.dart";

class UnifiedPushController extends AsyncNotifier<bool> {
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
      },
      onMessage: (message, instance) async {
        debugPrint("UP message received for $instance");
        if (message.decrypted == false) {
          throw Exception(
            "Failed to decrypt notification. Try toggling off and on UnifiedPush in settings.",
          );
        }
        final event = await ref
            .read(ClientController.provider.notifier)
            .handlePush(json.decode(String.fromCharCodes(message.content)));

        if (event == null ||
            event.unreadType?.shouldNotify() != true ||
            (!isInBackground &&
                await windowManager.isFocused().onError((_, _) => true) &&
                await ref.read(
                      KeyController.provider(KeyController.roomKey).future,
                    ) ==
                    event.roomId)) {
          if (isInBackground) exit(0);
          return;
        }

        final provider = RoomsController.provider.select(
          (rooms) => rooms[event.roomId],
        );

        if (ref.read(provider)?.metadata == null) {
          final completer = Completer<void>();

          final subscription = ref.listen(provider, (previous, next) {
            if (next?.metadata != null && !completer.isCompleted) {
              completer.complete();
            }
          }, fireImmediately: true);

          try {
            await completer.future.timeout(.new(seconds: 10));
          } on TimeoutException {
            // metadata didn't show up in time
          } finally {
            subscription.close();
          }
        }

        final room = ref.read(provider);
        final avatar = room?.metadata?.avatar;
        final icon = avatar == null
            ? null
            : await ref
                  .read(ClientController.provider.notifier)
                  .downloadMedia(.new(mxc: avatar, isAvatar: true));

        await ref
            .read(NotificationController.provider.notifier)
            .send(
              id: event.eventId.hashCode & 0x7fffffff,
              title: room?.metadata?.name ?? "New Event",
              icon: icon,
              payload: event.eventId,
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

    if (registered) {
      // Needs to be registered every startup
      await register(true);
    }

    return registered;
  }

  Future<void> register([bool alreadyRegistered = false]) async {
    state = .loading();
    try {
      final clientState = ref.watch(ClientStateController.provider);
      if (clientState?.deviceId == null) return;

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

      await UnifiedPush.register(
        instance: clientState!.deviceId!,
        vapid: capabilities.webpush?.vapid,
      );
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
