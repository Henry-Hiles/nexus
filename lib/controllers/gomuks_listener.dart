import "dart:async";
import "dart:ffi";

import "package:flutter/foundation.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/controllers/sync_status.dart";
import "package:nexus/controllers/top_level_spaces.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/main.dart";
import "package:ffi/ffi.dart";
import "package:nexus/models/event.dart";
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
            final decodedMuksEvent = data.toJson();

            switch (muksEventType) {
              case "client_state":
                ref
                    .watch(ClientStateController.provider.notifier)
                    .set(.fromJson(decodedMuksEvent));
                break;
              case "sync_status":
                ref
                    .watch(SyncStatusController.provider.notifier)
                    .set(.fromJson(decodedMuksEvent));
                break;
              case "init_complete":
                ref.watch(InitCompleteController.provider.notifier).complete();
                break;
              case "send_complete":
                final event = Event.fromJson(decodedMuksEvent["event"]);
                ref
                    .watch(RoomsController.provider.notifier)
                    .update(
                      .new({
                        event.roomId: .new(events: .new({event.rowId: event})),
                      }),
                      .new(),
                    );

                break;
              case "sync_complete":
                final syncData = SyncData.fromJson(decodedMuksEvent);
                final roomProvider = RoomsController.provider;
                final accountDataProvider = AccountDataController.provider;

                if (syncData.clearState) {
                  ref.invalidate(roomProvider);
                  ref.invalidate(accountDataProvider);
                }

                ref
                    .watch(roomProvider.notifier)
                    .update(syncData.rooms, syncData.leftRooms);
                ref
                    .watch(accountDataProvider.notifier)
                    .update(syncData.accountData);

                if (syncData.topLevelSpaces != null) {
                  ref
                      .watch(TopLevelSpacesController.provider.notifier)
                      .set(syncData.topLevelSpaces!);
                }

                if (syncData.spaceEdges != null) {
                  ref
                      .watch(SpaceEdgesController.provider.notifier)
                      .set(syncData.spaceEdges!);
                }

                // ref
                //     .watch(SyncStatusController.provider.notifier)
                //     .set(SyncStatus.fromJson(decodedMuksEvent));
                break;
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

    final errorCode = GomuksStart(handle, callable.nativeFunction);
    if (errorCode != 0) {
      throw Exception("GomuksStart returned error code $errorCode");
    }
  }

  static final provider = AsyncNotifierProvider<GomuksListenerController, void>(
    GomuksListenerController.new,
  );
}
