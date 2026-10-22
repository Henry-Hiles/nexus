import "dart:async";
import "dart:ffi";
import "dart:io";
import "dart:isolate";
import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:ffi/ffi.dart";
import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/gomuks_buffer.dart";
import "package:nexus/models/capabilities.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/event_context.dart";
import "package:nexus/models/mentions_response.dart";
import "package:nexus/models/gomuks_config.dart";
import "package:nexus/models/gomuks_exception.dart";
import "package:nexus/models/oauth_auth_code_response.dart";
import "package:nexus/models/open_graph_data.dart";
import "package:nexus/models/paginate.dart";
import "package:nexus/models/paginate_manual.dart";
import "package:nexus/models/requests/create_room.dart";
import "package:nexus/models/requests/deregister_pusher.dart";
import "package:nexus/models/requests/download_media.dart";
import "package:nexus/models/requests/get_event.dart";
import "package:nexus/models/requests/get_event_context.dart";
import "package:nexus/models/requests/get_mentions.dart";
import "package:nexus/models/requests/get_related_events.dart";
import "package:nexus/models/requests/get_room_state.dart";
import "package:nexus/models/requests/get_space_hierarchy.dart";
import "package:nexus/models/requests/join_room.dart";
import "package:nexus/models/profile_response.dart";
import "package:nexus/models/push_notification.dart";
import "package:nexus/models/recovery_key.dart";
import "package:nexus/models/requests/oauth/exchange_token.dart";
import "package:nexus/models/requests/oauth/get_auth_url.dart";
import "package:nexus/models/requests/oauth/register_client.dart";
import "package:nexus/models/requests/paginate.dart";
import "package:nexus/models/requests/paginate_manual.dart";
import "package:nexus/models/requests/redact_event.dart";
import "package:nexus/models/requests/register_pusher.dart";
import "package:nexus/models/requests/report.dart";
import "package:nexus/models/requests/search.dart";
import "package:nexus/models/requests/send_event.dart";
import "package:nexus/models/requests/send_message.dart";
import "package:nexus/models/requests/set_account_data.dart";
import "package:nexus/models/requests/set_membership.dart";
import "package:nexus/models/requests/set_state.dart";
import "package:nexus/models/requests/upload_media.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/room_summary.dart";
import "package:nexus/models/space_hierarchy.dart";
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
        try {
          GomuksSetEnv(keyPtr, valuePtr);
        } finally {
          calloc
            ..free(keyPtr)
            ..free(valuePtr);
        }
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
        calloc
          ..free(bufferPointer.ref.base)
          ..free(bufferPointer);
      }
    });

    if (!ref.mounted) {
      GomuksDestroy(handle);
      return Completer<int>().future;
    }

    ref.onDispose(() => GomuksDestroy(handle));

    return handle;
  }

  /// Calls gomuks with [data] as JSON, returning its decoded response.
  Future<dynamic> callGomuksMethod(
    Map<String, dynamic> data,
    void Function(
      int handle,
      GomuksOwnedBuffer data,
      Pointer<NativeFunction<Void Function(GomuksResponse)>> callback,
    )
    call,
  ) async {
    final handle = await future;
    final buffer = data.toGomuksOwnedBuffer();

    final completer = Completer<dynamic>();
    late final NativeCallable<Void Function(GomuksResponse)> callable;
    callable = .listener((GomuksResponse response) {
      callable.close();
      try {
        final json = response.buf.toJsonAndFree();

        if (response.command.cast<Utf8>().toDartString() == "error") {
          throw GomuksException(json.toString());
        }

        completer.complete(json);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    try {
      call(handle, buffer, callable.nativeFunction);
    } catch (_) {
      // gomuks never got the call, so it won't respond or free the buffer
      callable.close();
      GomuksFreeBuffer(buffer);
      rethrow;
    }

    return completer.future;
  }

  Future<PushNotification?> handlePush(Map<String, dynamic> data) async {
    final response = await callGomuksMethod(data, GomuksHandlePushAsync);

    return response?["notification"] == null
        ? null
        : .fromJson(response["notification"]);
  }

  Future<dynamic> _sendCommand(
    String command, [
    Map<String, dynamic> data = const {},
  ]) => callGomuksMethod(data, (handle, data, callback) {
    final commandPointer = command.toNativeUtf8().cast<Char>();
    try {
      GomuksSubmitCommandAsync(handle, commandPointer, data, callback);
    } finally {
      // gomuks copies the command name before returning
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

    return .fromJson(
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

  Future<RecoveryKey> generateRecoveryKey(String passphrase) async => .fromJson(
    await _sendCommand("generate_recovery_key", {"passphrase": passphrase}),
  );

  Future<void> resetEncryption(RecoveryKey key) =>
      _sendCommand("reset_encryption", key.toJson());

  Future<Uri?> getCrossSigningResetUrl(Uri homeserver) async {
    const action = "org.matrix.cross_signing_reset";
    final oauth = (await _sendCommand("get_login_flows", {
      "homeserver_url": homeserver.toString(),
    }))["oauth"];

    if (oauth?["account_management_uri"] case final String uri
        when (oauth["account_management_actions_supported"] as List?)?.contains(
              action,
            ) ??
            false) {
      final parsed = Uri.parse(uri);
      return parsed.replace(
        queryParameters: {...parsed.queryParameters, "action": action},
      );
    }
    return null;
  }

  Future<String> joinRoom(JoinRoomRequest request) async =>
      (await _sendCommand("join_room", request.toJson()))["room_id"];

  Future<String> knockRoom(JoinRoomRequest request) async =>
      (await _sendCommand("knock_room", request.toJson()))["room_id"];

  Future<String> createRoom(CreateRoomRequest request) async =>
      (await _sendCommand("create_room", request.toJson()))["room_id"];

  Future<SpaceHierarchy> getSpaceHierarchy(
    GetSpaceHierarchyRequest request,
  ) async =>
      .fromJson(await _sendCommand("get_space_hierarchy", request.toJson()));

  Future<RoomSummary> getRoomSummary(JoinRoomRequest request) async =>
      .fromJson(await _sendCommand("get_room_summary", request.toJson()));

  Future<void> leaveRoom(String roomId) =>
      _sendCommand("leave_room", {"room_id": roomId});

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

  Future<MentionsResponse> getMentions(GetMentionsRequest request) async =>
      .fromJson(await _sendCommand("get_mentions", request.toJson()));

  Future<Event?> getEvent(GetEventRequest request) async {
    final json = await _sendCommand("get_event", request.toJson());
    return json == null ? null : .fromJson(json);
  }

  Future<OpenGraphData> getUrlPreview(Uri url) async =>
      .fromJson(await _sendCommand("get_url_preview", {"url": url.toString()}));

  Future<Paginate> paginate(PaginateRequest request) async =>
      .fromJson(await _sendCommand("paginate", request.toJson()));

  Future<PaginateManual> paginateManual(PaginateManualRequest request) async =>
      .fromJson(await _sendCommand("paginate_manual", request.toJson()));

  Future<PaginateManual> searchLocal(SearchRequest request) async =>
      .fromJson(await _sendCommand("search_local", request.toJson()));

  Future<PaginateManual> searchServer(SearchRequest request) async =>
      .fromJson(await _sendCommand("search_server", request.toJson()));

  Future<EventContext> getEventContext(GetEventContextRequest request) async =>
      .fromJson(await _sendCommand("get_event_context", request.toJson()));

  Future<ProfileResponse> getProfile(String userId) async {
    try {
      return .fromJson(await _sendCommand("get_profile", {"user_id": userId}));
    } catch (_) {
      return .new(profile: .new(id: userId));
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

  Future<void> setTyping(String roomId, Duration timeout) => _sendCommand(
    "set_typing",
    {"room_id": roomId, "timeout": timeout.inMilliseconds},
  );

  Future<void> markRead(Room room) async {
    if (room.timeline.isEmpty || room.metadata == null) return;
    final eventRowId = room.timeline[room.timeline.keys.reduce(max)];
    final event = eventRowId == null ? null : room.events[eventRowId];

    if (event == null) return;

    // Private until settings have loaded, in case the user turned sending off
    final sendPublic =
        ref.read(SettingsController.provider).value?.readReceipts ==
        .showAndSend;

    await _sendCommand("mark_read", {
      "room_id": room.metadata!.id,
      "receipt_type": sendPublic ? "m.read" : "m.read.private",
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

  Future<IList<String>> getMutualRooms(String userId) async => IList(
    ((await _sendCommand("get_mutual_rooms", {"user_id": userId}))["joined"]
            as List?)
        ?.cast<String>(),
  );

  Future<SpecVersionsResponse> getSpecVersions() async =>
      .fromJson(await _sendCommand("get_versions"));

  Future<Capabilities> getCapabilities() async =>
      .fromJson((await _sendCommand("get_capabilities"))["capabilities"]);

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
