import "dart:async";
import "dart:ffi";
import "dart:io";
import "dart:isolate";
import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:ffi/ffi.dart";
import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/models/capabilities.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/gomuks_config.dart";
import "package:nexus/models/oauth_auth_code_response.dart";
import "package:nexus/models/open_graph_data.dart";
import "package:nexus/models/paginate.dart";
import "package:nexus/models/requests/deregister_pusher.dart";
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/models/requests/get_event.dart";
import "package:nexus/models/requests/get_mentions.dart";
import "package:nexus/models/requests/get_related_events.dart";
import "package:nexus/models/requests/get_room_state.dart";
import "package:nexus/models/requests/join_room.dart";
import "package:nexus/models/profile_response.dart";
import "package:nexus/models/requests/oauth/exchange_token.dart";
import "package:nexus/models/requests/oauth/get_auth_url.dart";
import "package:nexus/models/requests/oauth/register_client.dart";
import "package:nexus/models/requests/paginate.dart";
import "package:nexus/models/requests/redact_event.dart";
import "package:nexus/models/requests/register_pusher.dart";
import "package:nexus/models/requests/report.dart";
import "package:nexus/models/requests/send_event.dart";
import "package:nexus/models/requests/send_message.dart";
import "package:nexus/models/requests/set_account_data.dart";
import "package:nexus/models/requests/set_membership.dart";
import "package:nexus/models/requests/set_state.dart";
import "package:nexus/models/requests/upload_media.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/room_metadata.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/models/spec_versions_response.dart";
import "package:nexus/src/third_party/gomuks.g.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path_provider/path_provider.dart";

class ClientController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    debugPrint("Setting Gomuks env...");
    if (Platform.isAndroid || Platform.isIOS) {
      final env = {
        "GOMUKS_ROOT": (await getApplicationSupportDirectory()).path,
        "GOMUKS_CACHE_HOME": (await getApplicationCacheDirectory()).path,
      };
      for (final MapEntry(:key, :value) in env.entries) {
        final keyPtr = key.toNativeUtf8().cast<Char>();
        final valuePtr = value.toNativeUtf8().cast<Char>();
        GomuksSetEnv(keyPtr, valuePtr);
        calloc
          ..free(keyPtr)
          ..free(valuePtr);
      }
    }

    debugPrint("Initializing Gomuks...");
    final handle = await Isolate.run(() {
      final bufferPointer = GomuksConfig(
        matrix: .new(
          initialDeviceDisplayName:
              "Nexus on ${toBeginningOfSentenceCase(Platform.operatingSystem)}",
        ),
      ).toJson().toGomuksBufferPtr();

      try {
        return GomuksInit(bufferPointer.ref);
      } finally {
        calloc.free(bufferPointer);
      }
    });

    ref.onDispose(() => GomuksDestroy(handle));

    return handle;
  }

  Future<dynamic> callGomuksMethod(
    Map<String, dynamic> data,
    FutureOr<GomuksResponse> Function(int handle, GomuksBorrowedBuffer data)
    callback,
  ) async {
    final bufferPointer = data.toGomuksBufferPtr();
    final handle = await future;
    final response = await Isolate.run(
      () => callback(handle, bufferPointer.ref),
    );

    calloc.free(bufferPointer);

    final json = response.buf.toJson();
    if (response.command.cast<Utf8>().toDartString() == "error") {
      throw json;
    }

    return json;
  }

  Future<(Event, RoomMetadata)> handlePush(Map<String, dynamic> data) async {
    final response = await callGomuksMethod(
      data,
      (handle, data) async => GomuksHandlePush(handle, data),
    );

    return (
      Event.fromJson(response["event"]),
      RoomMetadata.fromJson(response["room"]),
    );
  }

  dynamic _sendCommand(
    String command, [
    Map<String, dynamic> data = const {},
  ]) => callGomuksMethod(data, (handle, data) {
    final commandPointer = command.toNativeUtf8().cast<Char>();
    try {
      return GomuksSubmitCommand(handle, commandPointer, data);
    } finally {
      calloc.free(commandPointer);
    }
  });

  Future<void> redactEvent(RedactEventRequest report) =>
      _sendCommand("redact_event", report.toJson());

  Future<Event> sendMessage(SendMessageRequest request) async =>
      Event.fromJson(await _sendCommand("send_message", request.toJson()));

  Future<Event> sendEvent(SendEventRequest request) async {
    final json = request.toJson();
    final content = request.content.toJson();

    return Event.fromJson(
      await _sendCommand("send_event", {
        ...json,
        "content": {
          ...content,
          "m.relates_to": {
            ...((content["m.relates_to"] as Map<String, dynamic>?) ?? {}),
            "event_id": request.relatesTo,
            "rel_type": request.relationType,
          },
        },
      }),
    );
  }

  Future<String?> setState(SetStateRequest request) async =>
      await _sendCommand("set_state", request.toJson());

  Future<String?> verify(String recoveryKey) async {
    try {
      await _sendCommand("verify", {"recovery_key": recoveryKey});
      return null;
    } catch (error) {
      return error.toString();
    }
  }

  Future<String> joinRoom(JoinRoomRequest request) async =>
      (await _sendCommand("join_room", request.toJson()))["room_id"];

  Future<RoomSummary> getRoomSummary(JoinRoomRequest request) async =>
      .fromJson(await _sendCommand("get_room_summary", request.toJson()));

  Future<void> leaveRoom(Room room) async {
    if (room.metadata == null) return;
    await _sendCommand("leave_room", {"room_id": room.metadata!.id});
  }

  Future<IList<Event>> getRoomState(GetRoomStateRequest request) async {
    Future<List?> getState(GetRoomStateRequest request) async =>
        (await _sendCommand("get_room_state", request.toJson())) as List?;
    final response = await getState(request);

    return .new(
      (response ?? await getState(request.copyWith(refetch: true)) ?? []).map(
        (event) => .fromJson(event),
      ),
    );
  }

  Future<IList<Event>?> getRelatedEvents(
    GetRelatedEventsRequest request,
  ) async {
    final response =
        (await _sendCommand("get_related_events", request.toJson())) as List?;
    return .new(response?.map((event) => .fromJson(event)));
  }

  Future<IList<Event>> getMentions(GetMentionsRequest request) async => .new(
    // TODO: Handle `related_events`
    ((await _sendCommand("get_mentions", request.toJson()))["events"] as List)
        .map((event) => .fromJson(event)),
  );

  Future<Event?> getEvent(GetEventRequest request) async {
    final json = await _sendCommand("get_event", request.toJson());
    return json == null ? null : .fromJson(json);
  }

  Future<OpenGraphData> getUrlPreview(Uri url) async =>
      .fromJson(await _sendCommand("get_url_preview", {"url": url.toString()}));

  Future<Paginate> paginate(PaginateRequest request) async =>
      .fromJson(await _sendCommand("paginate", request.toJson()));

  Future<ProfileResponse> getProfile(String userId) async {
    try {
      return .fromJson(await _sendCommand("get_profile", {"user_id": userId}));
    } catch (_) {
      return ProfileResponse(profile: .new(id: userId));
    }
  }

  Future<void> reportEvent(ReportRequest request) =>
      _sendCommand("report_event", request.toJson());

  Future<void> setMembership(SetMembershipRequest request) =>
      _sendCommand("set_membership", request.toJson());

  Future<void> setAccountData(SetAccountDataRequest request) =>
      _sendCommand("set_account_data", request.toJson());

  Future<void> registerPusher(RegisterPusherRequest request) =>
      _sendCommand("register_homeserver_push", request.toJson());

  Future<void> deregisterPusher(DeregisterPusherRequest request) =>
      _sendCommand("register_homeserver_push", {
        ...request.toJson(),
        "kind": null,
      });

  Future<MessageContent> uploadMedia(UploadMediaRequest request) async =>
      .fromJson(await _sendCommand("upload_media", request.toJson()));

  Future<File> downloadMedia(DownloadMediaRequest request) async =>
      .new((await _sendCommand("download_media", request.toJson()))["path"]);

  Future<void> logout() => _sendCommand("logout");

  Future<void> markRead(Room room) async {
    final eventRowId = room.timeline[room.timeline.keys.reduce(max)];
    final event = eventRowId == null ? null : room.events[eventRowId];
    if (event == null || room.metadata == null) return;

    await _sendCommand("mark_read", {
      "room_id": room.metadata!.id,
      "receipt_type": "m.read",
      "event_id": event.eventId,
    });
  }

  Future<String> registerClient(OAuthRegisterClientRequest request) async =>
      (await _sendCommand(
        "oauth_register_client",
        request.toJson(),
      ))["client_id"];

  Future<OAuthAuthCodeResponse> getAuthUrl(OAuthGetAuthUrl request) async =>
      .fromJson(
        await _sendCommand("oauth_get_authorization_url", request.toJson()),
      );

  Future<void> exchangeToken(OAuthExchangeTokenRequest request) async =>
      await _sendCommand("oauth_exchange_token", request.toJson());

  Future<SpecVersionsResponse> getSpecVersions() async =>
      .fromJson(await _sendCommand("get_versions"));

  Future<Capabilities> getCapabilities() async => Capabilities.fromJson(
    (await _sendCommand("get_capabilities"))["capabilities"],
  );

  Future<Uri?> discoverHomeserver(Uri homeserver) async {
    try {
      final response = await _sendCommand("discover_homeserver", {
        "user_id": "@fake-user:${homeserver.authority}",
      });
      return Uri.parse(response["m.homeserver"]?["base_url"]);
    } catch (error) {
      return null;
    }
  }

  static final provider = AsyncNotifierProvider<ClientController, int>(
    ClientController.new,
  );
}
