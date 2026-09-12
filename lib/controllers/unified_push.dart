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
import "package:nexus/models/requests/register_pusher.dart";
import "package:unifiedpush/unifiedpush.dart";
import "package:unifiedpush_storage_shared_preferences/storage.dart";
import "package:window_manager/window_manager.dart";

class UnifiedPushController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    final registered = await UnifiedPush.initialize(
      linuxOptions: .new(
        dbusName: "nexus.federated.nexus.UnifiedPush",
        storage: UnifiedPushStorageSharedPreferences(),
        background: isInBackground,
      ),
      onNewEndpoint: (endpoint, instance) async {
        final pushKey = endpoint.pubKeySet!.pubKey;
        await ref
            .watch(PushKeyController.provider(instance).notifier)
            .set(pushKey);

        await client.registerPusher(
          .new(
            appDisplayName: "Nexus",
            appId: "nexus.federated.nexus",
            data: PusherData.webPush(
              url: Uri.parse(endpoint.url),
              auth: endpoint.pubKeySet!.auth,
            ),
            deviceDisplayName:
                "Nexus on ${toBeginningOfSentenceCase(Platform.operatingSystem)}",
            kind: .webPush,
            lang: "en",
            pushKey: pushKey,
          ),
        );
      },
      onMessage: (message, instance) async {
        if (message.decrypted == false) {
          throw Exception(
            "Failed to decrypt notification. Try toggling off and on UnifiedPush in settings.",
          );
        }
        final event = await client.handlePush(
          json.decode(String.fromCharCodes(message.content)),
        );

        if (event == null ||
            event.unreadType?.shouldNotify() != true ||
            (!isInBackground &&
                await windowManager.isFocused().onError((_, _) => false) &&
                ref.watch(KeyController.provider(KeyController.roomKey)) ==
                    event.roomId)) {
          return;
        }

        final room = ref.read(
          RoomsController.provider.select((rooms) => rooms[event.roomId]),
        );

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
      onRegistrationFailed: (error, instance) => throw error,
      onUnregistered: (instance) async {
        await ref
            .watch(PushKeyController.provider(instance).notifier)
            .set(null);
        ref.invalidateSelf();
      },
    );

    if (registered) {
      // Needs to be registered every startup
      await register(true);
    }

    return registered;
  }

  Future<void> register([bool alreadyRegistered = false]) async {
    final clientState = ref.watch(ClientStateController.provider);
    if (clientState?.deviceId == null) ref.invalidateSelf();

    final capabilities = await ref
        .watch(ClientController.provider.notifier)
        .getCapabilities();

    if (capabilities.webpush?.vapid == null) {
      throw UnsupportedError(
        "Your homeserver does not support MSC4174 (Web Push), and therefore cannot send notifications to Nexus.",
      );
    }

    if (!alreadyRegistered &&
        !await UnifiedPush.tryUseCurrentOrDefaultDistributor()) {
      throw Exception("No UnifiedPush distributors found");
    }

    await UnifiedPush.register(
      instance: clientState!.deviceId!,
      vapid: capabilities.webpush?.vapid,
    );

    if (!alreadyRegistered) ref.invalidateSelf();
  }

  Future<void> deregister() async {
    final clientState = ref.watch(ClientStateController.provider);
    final key = ref.watch(PushKeyController.provider(clientState!.deviceId!));

    if (key != null) {
      await ref
          .watch(ClientController.provider.notifier)
          .deregisterPusher(.new(appId: "nexus.federated.nexus", pushKey: key));
    } else {
      debugPrint(
        "No matching pushKey found. Skipping deregistration from homeserver.",
      );
    }

    await UnifiedPush.unregister(clientState.deviceId!);
    ref.invalidateSelf();
  }

  static final provider = AsyncNotifierProvider<UnifiedPushController, bool>(
    UnifiedPushController.new,
  );
}
