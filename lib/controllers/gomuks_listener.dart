import "dart:async";
import "dart:ffi";
import "dart:isolate";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/invites.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/controllers/sync_status.dart";
import "package:nexus/controllers/top_level_spaces.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/main.dart";
import "package:ffi/ffi.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/events_decrypted.dart";
import "package:nexus/models/sync_data.dart";
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
          try {
            final muksEventType = command.cast<Utf8>().toDartString();
            debugPrint("Handling $muksEventType...");
            final decodedMuksEvent = data.toJsonAndFree();

            switch (muksEventType) {
              case "client_state":
                ref
                    .read(ClientStateController.provider.notifier)
                    .set(.fromJson(decodedMuksEvent));
              case "sync_status":
                ref
                    .read(SyncStatusController.provider.notifier)
                    .set(.fromJson(decodedMuksEvent));
              case "init_complete":
                ref.read(InitCompleteController.provider.notifier).complete();
              case "send_complete":
                final event = Event.fromJson(decodedMuksEvent["event"]);
                ref
                    .read(RoomsController.provider.notifier)
                    .update(
                      .new({
                        event.roomId: .new(events: .new({event.rowId: event})),
                      }),
                    );
              case "events_decrypted":
                final decrypted = EventsDecrypted.fromJson(decodedMuksEvent);
                final metadata = ref
                    .read(RoomsController.provider)[decrypted.roomId]
                    ?.metadata;

                ref
                    .read(RoomsController.provider.notifier)
                    .update(
                      .new({
                        decrypted.roomId: .new(
                          events: decrypted.events,
                          metadata: metadata?.copyWith(
                            previewEventRowID:
                                decrypted.previewEventRowID ??
                                metadata.previewEventRowID,
                            sortingTimestamp:
                                decrypted.sortingTimestamp ??
                                metadata.sortingTimestamp,
                          ),
                        ),
                      }),
                    );
              case "sync_complete":
                final syncData = SyncData.fromJson(decodedMuksEvent);
                final roomProvider = RoomsController.provider;
                final accountDataProvider = AccountDataController.provider;
                final invitesProvider = InvitesController.provider;

                if (syncData.clearState) {
                  ref.invalidate(roomProvider);
                  ref.invalidate(accountDataProvider);
                  ref.invalidate(invitesProvider);
                }

                ref
                    .read(roomProvider.notifier)
                    .update(syncData.rooms, syncData.leftRooms);
                ref
                    .read(accountDataProvider.notifier)
                    .update(syncData.accountData);
                ref
                    .read(invitesProvider.notifier)
                    .update(
                      syncData.invitedRooms,
                      joinedRooms: syncData.rooms.keys.toISet(),
                      leftRooms: syncData.leftRooms,
                    );

                if (syncData.topLevelSpaces case final topLevelSpaces?) {
                  ref
                      .read(TopLevelSpacesController.provider.notifier)
                      .set(topLevelSpaces);
                }

                if (syncData.spaceEdges case final spaceEdges?) {
                  ref
                      .read(SpaceEdgesController.provider.notifier)
                      .set(spaceEdges);
                }
              default:
                debugPrint("Unhandled event: $muksEventType");
            }
            debugPrint("Finished handling $muksEventType...");
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
