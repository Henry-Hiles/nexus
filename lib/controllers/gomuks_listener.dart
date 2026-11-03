import "dart:async";
import "dart:ffi";
import "dart:io";
import "dart:isolate";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/accounts.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/controllers/app_paused.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/controllers/sync_status.dart";
import "package:nexus/controllers/top_level_spaces.dart";
import "package:nexus/controllers/typing.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/main.dart";
import "package:ffi/ffi.dart";
import "package:nexus/models/gomuks_event.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class GomuksListenerController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    debugPrint("Starting gomuks...");
    final handle = await ref.watch(ClientController.provider.future);

    final callable =
        NativeCallable<
          Void Function(Pointer<Char>, Int64, GomuksOwnedBuffer)
        >.listener((
          Pointer<Char> command,
          int requestId,
          GomuksOwnedBuffer data,
        ) {
          final type = command.cast<Utf8>().toDartString();
          try {
            debugPrint("Handling $type...");
            switch (GomuksEvent.parse(type, data.toJsonAndFree())) {
              case ClientStateEvent(:final state):
                ref.read(ClientStateController.provider.notifier).set(state);
              case SyncStatusEvent(:final status):
                ref.read(SyncStatusController.provider.notifier).set(status);
              case InitCompleteEvent():
                ref.read(InitCompleteController.provider.notifier).complete();
              case SendCompleteEvent(:final event):
                ref.read(RoomsController.provider.notifier).storeEvents([
                  event,
                ]);
              case TypingEvent(:final typing):
                ref.read(TypingController.provider.notifier).set(typing);
              case EventsDecryptedEvent(:final decrypted):
                ref
                    .read(RoomsController.provider.notifier)
                    .handleDecrypted(decrypted);
              case SyncCompleteEvent(:final sync):
                ref.read(RoomsController.provider.notifier).handleSync(sync);
                ref
                    .read(AccountDataController.provider.notifier)
                    .handleSync(sync);
                ref.read(InvitesController.provider.notifier).handleSync(sync);
                ref.read(TypingController.provider.notifier).handleSync(sync);
                ref
                    .read(TopLevelSpacesController.provider.notifier)
                    .handleSync(sync);
                ref
                    .read(SpaceEdgesController.provider.notifier)
                    .handleSync(sync);
              case UnknownGomuksEvent():
                debugPrint("Unhandled event: $type");
            }
            debugPrint("Finished handling $type...");
          } catch (error, stackTrace) {
            if (kDebugMode) {
              debugPrintStack(stackTrace: stackTrace, label: error.toString());
              rethrow;
            } else {
              showError(error, stackTrace);
            }
          }
        });

    ref.onDispose(callable.close);

    final errorCode = await _start(handle, callable.nativeFunction);
    if (errorCode != 0) {
      throw Exception("GomuksStart returned error code $errorCode");
    }

    if (!ref.mounted) return;

    // Cached so the account switcher and push routing have them while the
    // account isn't active
    ref.listen(
      ClientStateController.provider.select(
        (state) => (state?.isInitialized, state?.userId, state?.deviceId),
      ),
      (_, ids) => Future(() async {
        final id = ref.read(ActiveAccountController.provider);
        final accounts = ref.read(AccountsController.provider.notifier);

        switch (ids) {
          // Logged out, so it shouldn't show as an account anymore
          case (true, null, _):
            await accounts.reset(id);
          case (_, final userId?, final deviceId):
            final previous = (await ref.read(
              AccountsController.provider.future,
            )).firstWhereOrNull((account) => account.id == id);
            final profile =
                (await ref
                        .read(ClientController.provider.notifier)
                        .getProfile(userId))
                    .profile;

            // Fetching the profile fails while offline, so keep what was cached
            await accounts.save(
              .new(
                id: id,
                userId: userId,
                deviceId: deviceId,
                displayName: profile.displayName ?? previous?.displayName,
                avatar: profile.avatarUrl ?? previous?.avatar,
              ),
            );
        }
      }).catchError(showError),
      fireImmediately: true,
    );

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile OSes block network access for backgrounded apps, so pause
      // syncing instead of letting it fail.
      ref.listen(AppPausedController.provider, (_, paused) {
        final client = ref.read(ClientController.provider.notifier);
        if (paused) {
          client.pauseSync().onError(showError);
        } else {
          ref.invalidate(TypingController.provider);
          client.resumeSync().onError(showError);
        }
      }, fireImmediately: true);
    }
  }

  /// Waits for gomuks to report the client's device ID
  Future<String> deviceId() {
    final completer = Completer<String>();
    final subscription = ref.listen(
      ClientStateController.provider.select((value) => value?.deviceId),
      (_, next) {
        if (next != null && !completer.isCompleted) completer.complete(next);
      },
      fireImmediately: true,
    );
    return completer.future.whenComplete(subscription.close);
  }

  static Future<int> _start(
    int handle,
    Pointer<
      NativeFunction<Void Function(Pointer<Char>, Int64, GomuksOwnedBuffer)>
    >
    callback,
  ) => Isolate.run(() => GomuksStart(handle, callback));

  static final provider = AsyncNotifierProvider<GomuksListenerController, void>(
    GomuksListenerController.new,
  );
}
