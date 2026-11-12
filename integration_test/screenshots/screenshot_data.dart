import "dart:convert";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space_edge.dart";

/// What the screenshots show: the Nexus space, with its room mid-conversation.
/// Rooms are written as gomuks reports them.
class ScreenshotData(final DateTime now) {
  static const me = "@quadradical:federated.nexus";
  static const bot = "@nexusbot:federated.nexus";
  static const alice = "@alice:example.org";
  static const pumpkin = "@pumpkin:example.org";
  static const strudel = "@strudel:example.org";
  static const opal = "@opal:example.org";
  static const greenTea = "@greentea:example.org";

  static const nexusSpace = "!nexus-space:federated.nexus";
  static const nexusRoom = "!nexus-client:federated.nexus";

  /// Nexus' own avatar, the app icon. Every other `mxc://screenshots/<file>` is
  /// a file in avatars/, see avatars/SOURCES.md.
  static const nexusAvatar = "mxc://screenshots/nexus";
  static const myAvatar = "mxc://screenshots/quadradical.webp";
  static const issueUrl = "https://git.federated.nexus/Nexus/nexus/issues/174";
  static const commitUrl =
      "https://git.federated.nexus/Nexus/nexus/commit/41f5225420";

  static const topic =
      "A simple and user-friendly Matrix client made with Flutter and a Gomuks backend.";

  /// The users shown, with their power level in the Nexus room. Those without
  /// an avatar get Nexus' fallback. Everyone but QuadRadical and NexusBot is
  /// made up, on example.org so as not to be anyone real.
  static const users = IListConst([
    (id: me, name: "QuadRadical", powerLevel: 100, avatar: myAvatar),
    (id: alice, name: "Alice", powerLevel: 100, avatar: null),
    (id: bot, name: "NexusBot", powerLevel: 50, avatar: nexusAvatar),
    (
      id: pumpkin,
      name: "Pumpkin",
      powerLevel: 0,
      avatar: "mxc://screenshots/pumpkin.webp",
    ),
    (
      id: strudel,
      name: "Strudel",
      powerLevel: 0,
      avatar: "mxc://screenshots/strudel.webp",
    ),
    (
      id: opal,
      name: "Opal",
      powerLevel: 0,
      avatar: "mxc://screenshots/opal.webp",
    ),
    (
      id: "@orange:example.org",
      name: "Orange",
      powerLevel: 0,
      avatar: "mxc://screenshots/orange.webp",
    ),
    (
      id: "@log1:example.org",
      name: "log(1)",
      powerLevel: 0,
      avatar: "mxc://screenshots/log-1.webp",
    ),
    (
      id: greenTea,
      name: "Green Tea",
      powerLevel: 0,
      avatar: "mxc://screenshots/green-tea.webp",
    ),
    (
      id: "@cinnamon:example.org",
      name: "Cinnamon",
      powerLevel: 0,
      avatar: "mxc://screenshots/cinnamon.webp",
    ),
  ]);

  /// The Nexus space's other rooms
  static const otherRooms = IListConst([
    (name: "Off-topic", unread: 3),
    (name: "Development", unread: 0),
  ]);

  /// Spaces shown in the rail besides Nexus, so it doesn't look empty
  static const otherSpaces = IListConst([
    "Matrix Community",
    "Flutter Devs",
    "Linux Mobile",
    "Rust",
    "Open Source Games",
    "Fediverse",
    "Self-Hosting",
  ]);

  static const clientState = ClientState(
    isInitialized: true,
    isLoggedIn: true,
    isVerified: true,
    userId: me,
    deviceId: "SCREENSHOTS",
    homeserverUrl: "https://federated.nexus",
  );

  static final IList<String> topLevelSpaces = .new([
    nexusSpace,
    ...otherSpaces.map(_roomId),
  ]);

  static final IMap<String, IList<SpaceEdge>> spaceEdges = .new({
    nexusSpace: .new(
      [
        nexusRoom,
        ...otherRooms.map((room) => _roomId(room.name)),
      ].map((id) => .new(childId: id)),
    ),
  });

  /// The rooms, with the Nexus room's state already fetched so it isn't
  /// requested
  late final IMap<String, Room> rooms = {
    nexusSpace: _room(nexusSpace, "Nexus Client", topic: topic),
    nexusRoom: _room(
      nexusRoom,
      "Nexus Client",
      topic: topic,
      lastEvent: timeline.last,
      extra: {
        "timeline": timeline
            .map(
              (event) => {
                "timeline_rowid": event["rowid"],
                "event_rowid": event["rowid"],
              },
            )
            .toList(),
        "events": [...nexusState, ...timeline],
        "state": _stateIndex(nexusState),
        "receipts": {
          timeline.last["event_id"]: [
            _receipt(strudel, timeline.last),
            _receipt(greenTea, timeline.last),
          ],
          timeline[timeline.length - 2]["event_id"]: [
            _receipt(opal, timeline[timeline.length - 2]),
          ],
        },
        "has_more": false,
      },
    ).copyWith(hasFetchedState: true, hasFetchedMembers: true),
    for (final room in otherRooms)
      _roomId(room.name): _room(
        _roomId(room.name),
        room.name,
        avatar: _avatarOfRoom(room.name),
        unread: room.unread,
      ),
    for (final space in otherSpaces)
      _roomId(space): _room(
        _roomId(space),
        space,
        avatar: _avatarOfRoom(space),
      ),
  }.lock;

  /// The Nexus room's state: who's in it, and their power levels
  late final List<Map<String, dynamic>> nexusState = [
    _event(me, "m.room.power_levels", {
      "users": Map.fromEntries(
        users.map((user) => .new(user.id, user.powerLevel)),
      ),
      "users_default": 0,
      "events_default": 0,
      "state_default": 50,
    }, key: ""),
    ...users.map(
      (user) => _event(user.id, "m.room.member", {
        "membership": "join",
        "displayname": user.name,
        "avatar_url": ?user.avatar,
      }, key: user.id),
    ),
  ];

  late final List<Map<String, dynamic>> timeline = [
    _message(
      alice,
      35,
      "the screenshots in the readme are pretty out of date btw",
    ),
    _message(
      me,
      32,
      "Should I:\n"
      "1. just take screenshots on a few devices, and redo them whenever the "
      "UI changes\n"
      "or\n"
      "2. overengineer a test that makes them automatically, in a fake room\n"
      "I think the answer is 2 :p",
      html:
          "Should I:"
          "<ol><li>just take screenshots on a few devices, and redo them "
          "whenever the UI changes</li></ol>"
          "or"
          '<ol start="2"><li>overengineer a test that makes them '
          "automatically, in a fake room</li></ol>"
          "I think the answer is 2 :p",
      reactions: {"2️⃣": 3},
    ),
    _message(pumpkin, 30, "2, obviously"),
    // Linked only in the HTML, so the body has no link to preview
    _message(
      bot,
      29,
      "[Nexus/nexus] Issue opened: #174 Automatic scripts to make screenshots "
      "for different pages and viewports by Henry-Hiles",
      html:
          '[Nexus/nexus] Issue opened: <a href="$issueUrl">#174 Automatic '
          "scripts to make screenshots for different pages and viewports</a> "
          "by Henry-Hiles",
    ),
    _message(
      bot,
      7,
      "[Nexus/nexus] Henry-Hiles pushed 1 commit to main: $commitUrl: "
      "update screenshots - Henry-Hiles",
      html:
          "[Nexus/nexus] Henry-Hiles pushed 1 commit to main:<br>"
          '<a href="$commitUrl">41f5225</a>: update screenshots - Henry-Hiles',
      reactions: {"🚀": 3},
    ),
    _message(
      pumpkin,
      5,
      "they're generated now?? let's gooo",
      reactions: {"🎉": 2, "❤️": 1},
    ),
  ];

  /// The link preview shown under NexusBot's message
  static const urlPreview = {
    "og:title": "update screenshots · 41f5225420",
    "og:description":
        "nexus - A simple and user-friendly Matrix client made with Flutter "
        "and a Gomuks backend.",
  };

  int _rowId = 0;

  /// An event in the Nexus room
  Map<String, dynamic> _event(
    String sender,
    String type,
    Map<String, dynamic> content, {
    String? key,
    int minutesAgo = 60,
    Map<String, int> reactions = const {},
  }) {
    final rowId = ++_rowId;
    return {
      "rowid": rowId,
      "timeline_rowid": rowId,
      "room_id": nexusRoom,
      "event_id": "\$screenshots-$rowId",
      "sender": sender,
      "type": type,
      "state_key": ?key,
      "timestamp": now
          .subtract(.new(minutes: minutesAgo))
          .millisecondsSinceEpoch,
      "content": content,
      "reactions": reactions,
    };
  }

  Map<String, dynamic> _message(
    String sender,
    int minutesAgo,
    String body, {
    String? html,
    Map<String, int> reactions = const {},
  }) => _event(
    sender,
    "m.room.message",
    {
      "msgtype": sender == bot ? "m.notice" : "m.text",
      "body": body,
      if (html != null) ...{
        "format": "org.matrix.custom.html",
        "formatted_body": html,
      },
    },
    minutesAgo: minutesAgo,
    reactions: reactions,
  );

  Map<String, dynamic> _receipt(String userId, Map<String, dynamic> event) => {
    "user_id": userId,
    "event_id": event["event_id"],
    "room_id": nexusRoom,
    "timestamp": event["timestamp"],
  };

  /// A room, with [extra] JSON besides its metadata
  Room _room(
    String id,
    String name, {
    String avatar = nexusAvatar,
    String? topic,
    int unread = 0,
    Map<String, dynamic>? lastEvent,
    Map<String, dynamic> extra = const {},
  }) => .fromJson(
    // Round-tripped, so the JSON has the types gomuks' decoded JSON would
    jsonDecode(
      jsonEncode({
        "meta": {
          "room_id": id,
          "name": name,
          "avatar": avatar,
          "topic": ?topic,
          "has_member_list": true,
          "preview_event_rowid": lastEvent?["rowid"] ?? 0,
          "sorting_timestamp":
              lastEvent?["timestamp"] ??
              now.subtract(const .new(hours: 1)).millisecondsSinceEpoch,
          "unread_highlights": 0,
          "unread_notifications": 0,
          "unread_messages": unread,
        },
        ...extra,
      }),
    ),
  );

  static Map<String, Map<String, int>> _stateIndex(
    List<Map<String, dynamic>> state,
  ) => state
      .groupListsBy((event) => event["type"] as String)
      .map(
        (type, events) => .new(
          type,
          Map.fromEntries(
            events.map(
              (event) =>
                  .new(event["state_key"] as String, event["rowid"] as int),
            ),
          ),
        ),
      );

  static String _avatarOfRoom(String name) =>
      "mxc://screenshots/${_slug(name)}.webp";

  static String _slug(String name) =>
      name.toLowerCase().replaceAll(RegExp("[^a-z]+"), "-");

  static String _roomId(String name) => "!${_slug(name)}:federated.nexus";
}
