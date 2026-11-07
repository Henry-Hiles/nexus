import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:http/http.dart" as http;

const homeserver = String.fromEnvironment("NEXUS_E2E_HOMESERVER");

/// A user acting over the client-server API directly, as a control for the
/// tests: it doesn't go through gomuks or any other Nexus code, so it sets
/// things up and checks the server's side independently of what's being
/// tested. That includes Nexus' models, so the JSON it sends is written out
/// here rather than built the way Nexus builds it.
class const MatrixUser(final String userId, final String accessToken) {
  static Future<MatrixUser> login(String username, String password) async {
    final json = await request(
      "POST",
      "/_matrix/client/v3/login",
      body: {
        "type": "m.login.password",
        "identifier": {"type": "m.id.user", "user": username},
        "password": password,
      },
    );
    return MatrixUser(json["user_id"], json["access_token"]);
  }

  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    String? accessToken,
    Object? body,
  }) async {
    final httpRequest =
        http.Request(method, Uri.parse(homeserver).resolve(path))
          ..headers.addAll({
            "Content-Type": "application/json",
            if (accessToken != null) "Authorization": "Bearer $accessToken",
          });
    if (method != "GET") httpRequest.body = jsonEncode(body ?? {});
    final response = await http.Response.fromStream(await httpRequest.send());

    if (response.statusCode == 429) {
      final retryAfter = jsonDecode(response.body)["retry_after_ms"] ?? 1000;
      await Future.delayed(.new(milliseconds: retryAfter));
      return request(method, path, accessToken: accessToken, body: body);
    }
    if (response.statusCode >= 300) {
      throw StateError(
        "$method $path failed with ${response.statusCode}: ${response.body}",
      );
    }
    return jsonDecode(response.body);
  }

  Future<String> createRoom(String name) async => (await request(
    "POST",
    "/_matrix/client/v3/createRoom",
    accessToken: accessToken,
    body: {"name": name, "preset": "private_chat"},
  ))["room_id"];

  Future<void> invite(String roomId, String userId) => request(
    "POST",
    "/_matrix/client/v3/rooms/${Uri.encodeComponent(roomId)}/invite",
    accessToken: accessToken,
    body: {"user_id": userId},
  );

  Future<void> join(String roomId) => request(
    "POST",
    "/_matrix/client/v3/join/${Uri.encodeComponent(roomId)}",
    accessToken: accessToken,
  );

  Future<void> logout() =>
      request("POST", "/_matrix/client/v3/logout", accessToken: accessToken);

  Future<String> sendEvent(
    String roomId,
    String type,
    Map<String, Object> content,
  ) async => (await request(
    "PUT",
    "/_matrix/client/v3/rooms/${Uri.encodeComponent(roomId)}/send/$type/"
        "${DateTime.now().microsecondsSinceEpoch}",
    accessToken: accessToken,
    body: content,
  ))["event_id"];

  /// Sends a text message. With [threadRoot] it's a reply in that thread, and
  /// otherwise with [replyTo] it's a reply to that event.
  Future<String> send(
    String roomId,
    String body, {
    String? threadRoot,
    String? replyTo,
  }) => sendEvent(roomId, "m.room.message", {
    "msgtype": "m.text",
    "body": body,
    "m.relates_to": ?switch ((threadRoot, replyTo)) {
      (final threadRoot?, _) => {
        "rel_type": "m.thread",
        "event_id": threadRoot,
        "is_falling_back": true,
        "m.in_reply_to": {"event_id": threadRoot},
      },
      (null, final replyTo?) => {
        "m.in_reply_to": {"event_id": replyTo},
      },
      (null, null) => null,
    },
  });

  /// Sends [rootBody], then [replies] in a thread from it, oldest first.
  Future<({String rootId, IList<String> replyIds})> sendThread(
    String roomId,
    String rootBody,
    IList<String> replies,
  ) async {
    final rootId = await send(roomId, rootBody);
    // One at a time, so they're in order (oops earlier tests weren't reproducable)
    final replyIds = await Stream.fromIterable(replies)
        .asyncMap((body) => send(roomId, body, threadRoot: rootId))
        .toList();
    return (rootId: rootId, replyIds: replyIds.toIList());
  }

  /// Edits the text message [eventId] to say [body].
  Future<String> edit(String roomId, String eventId, String body) =>
      sendEvent(roomId, "m.room.message", {
        "msgtype": "m.text",
        "body": "* $body",
        "m.new_content": {"msgtype": "m.text", "body": body},
        "m.relates_to": {"rel_type": "m.replace", "event_id": eventId},
      });

  Future<void> redact(String roomId, String eventId) => request(
    "PUT",
    "/_matrix/client/v3/rooms/${Uri.encodeComponent(roomId)}/redact/"
        "${Uri.encodeComponent(eventId)}/${DateTime.now().microsecondsSinceEpoch}",
    accessToken: accessToken,
  );

  /// The bodies of the replies in the thread from [threadRoot], oldest first.
  Future<IList<String>> threadReplies(String roomId, String threadRoot) async {
    final json = await request(
      "GET",
      "/_matrix/client/v1/rooms/${Uri.encodeComponent(roomId)}/relations/"
          "${Uri.encodeComponent(threadRoot)}/m.thread?dir=f&limit=100",
      accessToken: accessToken,
    );
    return (json["chunk"] as List)
        .map((event) => event["content"]["body"] as String)
        .toIList();
  }

  Future<IList<String>> threadRepliesIncluding(
    String roomId,
    String threadRoot,
    String body, {
    int attempts = 20,
  }) async {
    final replies = await threadReplies(roomId, threadRoot);
    if (replies.contains(body) || attempts <= 1) return replies;

    await Future.delayed(const .new(milliseconds: 500));
    return threadRepliesIncluding(
      roomId,
      threadRoot,
      body,
      attempts: attempts - 1,
    );
  }
}
