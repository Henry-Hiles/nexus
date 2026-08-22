import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
import "package:nexus/models/profile_response.dart";

part "event.freezed.dart";
part "event.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Event({
  @JsonKey(name: "rowid") required final int rowId,
  @JsonKey(name: "timeline_rowid") required final int timelineRowId,
  final String? stateKey,
  required final String roomId,
  required final String eventId,
  required final String sender,
  @JsonKey(readValue: Event.typeJsonFromJson) required final String type,
  @EpochDateTimeConverter() @override required final DateTime timestamp,
  final IMap<String, dynamic> unsigned = const IMap.empty(),
  final LocalContent? localContent,
  final String? transactionId,
  final String? redactedBy,
  final String? relatesTo,
  final String? relationType,
  final String? replyTo,
  final String? decryptionError,
  final String? sendError,
  final IMap<String, int> reactions = const IMap.empty(),
  @JsonKey(name: "last_edit_rowid") @override final int lastEditRowId = 0,
  @UnreadTypeConverter() @override final UnreadType? unreadType,
  final Profile? pmp,
  required final Content content,
  required final Content? previousContent,
}) with _$Event {
  Map<String, Object?> toJson() => _$EventToJson(this);

  static String typeJsonFromJson(Map<dynamic, dynamic> json, _) =>
      json["decrypted_type"] ?? json["type"];

  static Map<String, dynamic> getContentFromJson(Map<dynamic, dynamic> json) {
    final content = json["decrypted"] ?? json["content"];

    return content["m.new_content"] ?? content;
  }

  static String? replyToFromJson(Map<dynamic, dynamic> json) {
    try {
      return json["m.relates_to"]?["m.in_reply_to"]?["event_id"];
    } catch (_) {
      return null;
    }
  }

  factory Event.fromJson(Map<String, dynamic> json) =>
      _$EventFromJson(json).copyWith(
        replyTo: replyToFromJson(getContentFromJson(json)),
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

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const LocalContent({
  final String? sanitizedHtml,
  final String? editSource,
  final bool? wasPlaintext,
  final bool? bigEmoji,
  final bool? hasMath,
  final bool? replyFallbackRemoved,
}) with _$LocalContent {
  Map<String, Object?> toJson() => _$LocalContentToJson(this);

  @override
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
