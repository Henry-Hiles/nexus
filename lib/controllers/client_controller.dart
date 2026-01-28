import "dart:developer";
import "dart:ffi";
import "dart:isolate";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:ffi/ffi.dart";
import "package:flutter/foundation.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/space_edges_controller.dart";
import "package:nexus/controllers/sync_status_controller.dart";
import "package:nexus/controllers/top_level_spaces_controller.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/get_event_request.dart";
import "package:nexus/models/get_related_events_request.dart";
import "package:nexus/models/login_request.dart";
import "package:nexus/models/profile.dart";
import "package:nexus/models/report_request.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/sync_data.dart";
import "package:nexus/models/sync_status.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ClientController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final handle = await Isolate.run(GomuksInit);

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
                    .set(ClientState.fromJson(decodedMuksEvent));
                break;
              case "sync_status":
                ref
                    .watch(SyncStatusController.provider.notifier)
                    .set(SyncStatus.fromJson(decodedMuksEvent));
                break;
              case "sync_complete":
                final syncData = SyncData.fromJson(decodedMuksEvent);
                final roomProvider = RoomsController.provider;

                if (syncData.clearState) ref.invalidate(roomProvider);
                ref
                    .watch(roomProvider.notifier)
                    .update(syncData.rooms, syncData.leftRooms);
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
              case "typing":
                //TODO: IMPL
                break;
              default:
                debugPrint("Unhandled event: $muksEventType");
            }
            debugPrint("Finished handling $muksEventType...");
          } catch (error, stackTrace) {
            debugger();
            debugPrintStack(stackTrace: stackTrace, label: error.toString());
          }
        });

    ref.onDispose(() => GomuksDestroy(handle));
    ref.onDispose(callable.close);

    final errorCode = GomuksStart(handle, callable.nativeFunction);

    if (errorCode == 0) return handle;
    throw Exception("GomuksStart returned error code $errorCode");
  }

  Future<dynamic> sendCommand(String command, Map<String, dynamic> data) async {
    final bufferPointer = data.toGomuksBufferPtr();
    final handle = await future;
    final response = await Isolate.run(
      () => GomuksSubmitCommand(
        handle,
        command.toNativeUtf8().cast<Char>(),
        bufferPointer.ref,
      ),
    );

    calloc.free(bufferPointer);

    return response.buf.toJson();
  }

  Future<bool> verify(String recoveryKey) async {
    try {
      await sendCommand("verify", {"recovery_key": recoveryKey});
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<void> leaveRoom(Room room) async {
    if (room.metadata == null) return;
    await sendCommand("leave_room", {"room_id": room.metadata!.id});
  }

  Future<IList<Event>?> getRelatedEvents(
    GetRelatedEventsRequest request,
  ) async {
    final response =
        (await sendCommand("get_related_events", request.toJson())) as List?;
    return response?.map((event) => Event.fromJson(event)).toIList();
  }

  Future<Event?> getEvent(GetEventRequest request) async {
    final json = await sendCommand("get_event", request.toJson());

    return json == null ? null : Event.fromJson(json);
  }

  Future<Profile?> getProfile(String userId) async {
    final json = await sendCommand("get_profile", {"user_id": userId});

    return json == null ? null : Profile.fromJson(json);
  }

  Future<void> reportEvent(ReportRequest report) =>
      sendCommand("report_event", report.toJson());

  Future<void> markRead(Room room) async {
    if (room.events.isEmpty || room.metadata == null) return;
    await sendCommand("mark_read", {
      "room_id": room.metadata?.id,
      "receipt_type": "m.read",
      "event_id": room.events.last.eventId,
    });
  }

  Future<bool> login(LoginRequest login) async {
    try {
      await sendCommand("login", login.toJson());
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<String?> discoverHomeserver(Uri homeserver) async {
    try {
      final response = await sendCommand("discover_homeserver", {
        "user_id": "@fakeuser:${homeserver.host}",
      });
      return response["m.homeserver"]?["base_url"];
    } catch (error) {
      return null;
    }
  }

  static final provider = AsyncNotifierProvider<ClientController, int>(
    ClientController.new,
  );
}
