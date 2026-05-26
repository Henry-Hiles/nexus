import "package:collection/collection.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/canonical_alias.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/encryption.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/pinned_events.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/content/reaction.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/redaction.dart";
import "package:nexus/models/content/server_acl.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/content/history_visibility.dart";

class Content {
  final Error? parseError;
  Content({this.parseError});

  factory Content.fromJson(Map<String, dynamic> json) => Content();
  Map<String, dynamic> toJson() => {};

  static Map<String, dynamic> readValue(Map<dynamic, dynamic> json, _) =>
      json["decrypted"] ?? json["content"];

  static Content fromEventJson(Map<String, dynamic> json, String type) {
    try {
      return (EventType.values
              .firstWhereOrNull((eventType) => eventType.type == type)
              ?.contentFromJson ??
          Content.fromJson)(json);
    } catch (error) {
      if (error is Error) return Content(parseError: error);
      rethrow;
    }
  }
}

enum EventType {
  encrypted("m.room.encrypted", EncryptedContent.fromJson),
  redaction("m.room.redaction", RedactionContent.fromJson),
  encryption("m.room.encryption", EncryptionContent.fromJson),
  membership("m.room.member", MembershipContent.fromJson),
  create("m.room.create", CreateContent.fromJson),
  historyVisibility(
    "m.room.history_visibility",
    HistoryVisibilityContent.fromJson,
  ),
  canonicalAlias("m.room.canonical_alias", CanonicalAliasContent.fromJson),
  sticker("m.sticker", StickerContent.fromJson),
  joinRules("m.room.join_rules", JoinRulesContent.fromJson),
  powerLevels("m.room.power_levels", PowerLevelsContent.fromJson),
  serverACL("m.room.server_acl", ServerACLContent.fromJson),
  avatar("m.room.avatar", AvatarContent.fromJson),
  topic("m.room.topic", TopicContent.fromJson),
  name("m.room.name", NameContent.fromJson),
  reaction("m.reaction", ReactionContent.fromJson),
  pinnedEvents("m.room.pinned_events", PinnedEventsContent.fromJson),
  message("m.room.message", MessageContent.fromJson);

  final String type;
  final Content Function(Map<String, dynamic> json) contentFromJson;
  const EventType(this.type, this.contentFromJson);
}
