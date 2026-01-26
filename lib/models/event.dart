import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/epoch_date_time_converter.dart";
part "event.freezed.dart";
part "event.g.dart";

@freezed
abstract class Event with _$Event {
  const factory Event({
    @JsonKey(name: "rowid") required int rowId,
    @JsonKey(name: "timeline_rowid") required int timelineRowId,
    required String roomId,
    required int eventId,
    @JsonKey(name: "sender") required int authorId,
    required String type,
    required String stateKey,
    @EpochDateTimeConverter() required DateTime timestamp,
    required Map<String, dynamic> content,
    required Map<String, dynamic> decrypted,
    required Map<String, dynamic> decryptedType,
    required Map<String, dynamic> unsigned,
    required LocalContent localContent,
    required String transactionId,
    required String redactedBy,
    required String relatesTo,
    required String relatesType,
    required String decryptionError,
    required String sendError,
    required Map<String, int> reactions,
    required int lastEditRowId,
    @UnreadTypeConverter() UnreadType? unreadType,
  }) = _Event;

  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);
}

@freezed
abstract class LocalContent with _$LocalContent {
  const factory LocalContent({
    required String sanitizedHtml,
    required String htmlVersion,
    required bool wasPlaintext,
    required bool bigEmoji,
    required bool hasMath,
    required String editSource,
    required String replyFallbackRemoved,
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
