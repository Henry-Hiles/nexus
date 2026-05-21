import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/profile.dart";
part "event.freezed.dart";
part "event.g.dart";

@freezed
abstract class Event with _$Event {
  static String typeJsonFromJson(Map<dynamic, dynamic> json, _) =>
      json["decrypted_type"] ?? json["type"];

  static Map<String, dynamic> getContentFromJson(Map<dynamic, dynamic> json) {
    final content = json["decrypted"] ?? json["content"];

    return content["m.new_content"] ?? content;
  }

  const factory Event({
    @JsonKey(name: "rowid") required int rowId,
    @JsonKey(name: "timeline_rowid") required int timelineRowId,
    required String roomId,
    required String eventId,
    required String sender,
    @JsonKey(readValue: Event.typeJsonFromJson) required String type,
    String? stateKey,
    @EpochDateTimeConverter() required DateTime timestamp,
    @Default(IMap.empty()) IMap<String, dynamic> unsigned,
    LocalContent? localContent,
    String? transactionId,
    String? redactedBy,
    String? relatesTo,
    String? relationType,
    String? replyTo,
    String? decryptionError,
    String? sendError,
    @Default(IMap.empty()) IMap<String, int> reactions,
    @JsonKey(name: "last_edit_rowid") @Default(0) int lastEditRowId,
    @UnreadTypeConverter() UnreadType? unreadType,
    Profile? pmp,
    required Content content,
    required Content? previousContent,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) =>
      _$EventFromJson(json).copyWith(
        replyTo: getContentFromJson(
          json,
        )["m.relates_to"]?["m.in_reply_to"]?["event_id"],
        pmp: json["content"]?["com.beeper.per_message_profile"] == null
            ? null
            : Profile.fromJsonWithCatch(
                json["content"]?["com.beeper.per_message_profile"],
              ),
        content: Content.fromEventJson(
          getContentFromJson(json),
          json["decrypted_type"] ?? json["type"],
        ),
        previousContent: json["unsigned"]?["prev_content"] == null
            ? null
            : Content.fromEventJson(
                json["unsigned"]?["prev_content"],
                json["decrypted_type"] ?? json["type"],
              ),
      );
}

@freezed
abstract class LocalContent with _$LocalContent {
  const factory LocalContent({
    String? sanitizedHtml,
    String? editSource,
    bool? wasPlaintext,
    bool? bigEmoji,
    bool? hasMath,
    bool? replyFallbackRemoved,
  }) = _LocalContent;

  factory LocalContent.fromJson(Map<String, Object?> json) =>
      _$LocalContentFromJson(json);
}

class UnreadTypeConverter implements JsonConverter<UnreadType?, int?> {
  const UnreadTypeConverter();

  @override
  UnreadType? fromJson(int? json) => json == null ? null : UnreadType(json);

  @override
  int? toJson(UnreadType? object) => object?.value;
}

// I think this is correct but I'm not sure, its some type of bitmask.
@immutable
class UnreadType {
  final int value;

  const UnreadType(this.value);

  static const none = UnreadType(0);
  static const normal = UnreadType(1);
  static const notify = UnreadType(2);
  static const highlight = UnreadType(4);
  static const sound = UnreadType(8);

  bool get isNone => value == 0;
  bool get isNormal => (value & 1) != 0;
  bool get shouldNotify => (value & 2) != 0;
  bool get isHighlighted => (value & 4) != 0;
  bool get playsSound => (value & 8) != 0;
}
