import "dart:developer";
import "dart:ffi";
import "dart:io";
import "dart:isolate";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:ffi/ffi.dart";
import "package:flutter/foundation.dart";
import "package:nexus/controllers/account_data_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/init_complete_controller.dart";
import "package:nexus/controllers/room_chat_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/space_edges_controller.dart";
import "package:nexus/controllers/sync_status_controller.dart";
import "package:nexus/controllers/top_level_spaces_controller.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/main.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/paginate.dart";
import "package:nexus/models/requests/get_event_request.dart";
import "package:nexus/models/requests/get_related_events_request.dart";
import "package:nexus/models/requests/get_room_state_request.dart";
import "package:nexus/models/requests/join_room_request.dart";
import "package:nexus/models/requests/login_request.dart";
import "package:nexus/models/profile.dart";
import "package:nexus/models/requests/paginate_request.dart";
import "package:nexus/models/requests/redact_event_request.dart";
import "package:nexus/models/requests/report_request.dart";
import "package:nexus/models/requests/send_event_request.dart";
import "package:nexus/models/requests/send_message_request.dart";
import "package:nexus/models/requests/set_membership_request.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/sync_data.dart";
import "package:nexus/models/sync_status.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path_provider/path_provider.dart";

class ClientController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final Pointer<Char> root;
    if (Platform.isAndroid) {
      final dir = await getApplicationSupportDirectory();
      root = "${dir.path}/gomuks".toNativeUtf8().cast();
    } else {
      root = nullptr.cast();
    }

    final handle = GomuksInit(root);

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
              case "init_complete":
                ref.watch(InitCompleteController.provider.notifier).complete();
                break;
              case "send_complete":
                final event = Event.fromJson(decodedMuksEvent["event"]);

                if (event.type == "m.room.message") {
                  final provider = RoomChatController.provider(event.roomId);
                  if (ref.exists(provider)) {
                    ref.watch(provider.notifier).addEvent(event);
                  }
                }
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
            debugPrintStack(stackTrace: stackTrace, label: error.toString());
            debugger();
            showError(error, stackTrace);
          }
        });

    ref.onDispose(() => GomuksDestroy(handle));
    ref.onDispose(callable.close);

    final errorCode = GomuksStart(handle, callable.nativeFunction);

    if (errorCode == 0) return handle;
    throw Exception("GomuksStart returned error code $errorCode");
  }

  Future<dynamic> _sendCommand(
    String command, [
    Map<String, dynamic> data = const {},
  ]) async {
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

    final json = response.buf.toJson();
    if (json is String) throw json;
    return json;
  }

  Future<void> redactEvent(RedactEventRequest report) =>
      _sendCommand("redact_event", report.toJson());

  Future<Event> sendMessage(SendMessageRequest request) async =>
      Event.fromJson(await _sendCommand("send_message", request.toJson()));

  Future<Event> sendEvent(SendEventRequest request) async =>
      Event.fromJson(await _sendCommand("send_event", request.toJson()));

  Future<String?> verify(String recoveryKey) async {
    try {
      await _sendCommand("verify", {"recovery_key": recoveryKey});
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String> joinRoom(JoinRoomRequest request) async {
    final response = await _sendCommand("join_room", request.toJson());
    return response["room_id"];
  }

  Future<String?> getAccessToken() async {
    final response = await _sendCommand("get_account_info", {});
    return response?["access_token"];
  }

  Future<void> leaveRoom(Room room) async {
    if (room.metadata == null) return;
    await _sendCommand("leave_room", {"room_id": room.metadata!.id});
  }

  // (await _sendCommand("get_event_context", {
  //   "room_id": request.roomId,
  //   "event_id": r"$OqZT4NuTj0J1-771IOEEWRI4XdumRNu6ighlvO3K3gc",
  // }));

  Future<IList<Event>> getRoomState(GetRoomStateRequest request) async {
    Future<List?> getState(GetRoomStateRequest request) async =>
        (await _sendCommand("get_room_state", request.toJson())) as List?;
    final response = await getState(request);

    return (response ?? await getState(request.copyWith(refetch: true)) ?? [])
        .map((event) => Event.fromJson(event))
        .toIList();
  }

  Future<IList<Event>?> getRelatedEvents(
    GetRelatedEventsRequest request,
  ) async {
    final response =
        (await _sendCommand("get_related_events", request.toJson())) as List?;
    return response?.map((event) => Event.fromJson(event)).toIList();
  }

  Future<Event?> getEvent(GetEventRequest request) async {
    final event = request.room.events.firstWhereOrNull(
      (event) => event.eventId == request.eventId,
    );
    if (event != null) return event;

    final json = await _sendCommand("get_event", request.toJson());
    return json == null ? null : Event.fromJson(json);
  }

  Future<Paginate> paginate(PaginateRequest request) async =>
      Paginate.fromJson(await _sendCommand("paginate", request.toJson()));

  Future<Profile> getProfile(String userId) async =>
      Profile.fromJson(await _sendCommand("get_profile", {"user_id": userId}));

  Future<void> reportEvent(ReportRequest request) =>
      _sendCommand("report_event", request.toJson());

  Future<void> setMembership(SetMembershipRequest request) =>
      _sendCommand("set_membership", request.toJson());

  Future<void> markRead(Room room) async {
    final event = room.events.firstWhereOrNull(
      (event) => event.rowId == room.timeline.last.eventRowId,
    );
    if (event == null || room.metadata == null) return;

    await _sendCommand("mark_read", {
      "room_id": room.metadata!.id,
      "receipt_type": "m.read",
      "event_id": event.eventId,
    });
  }

  Future<String?> login(LoginRequest login) async {
    try {
      await _sendCommand("login", login.toJson());
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String?> discoverHomeserver(Uri homeserver) async {
    try {
      final response = await _sendCommand("discover_homeserver", {
        "user_id": "@fake-user:${homeserver.host}",
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
