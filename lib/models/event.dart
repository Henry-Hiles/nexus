import "package:fast_immutable_collections/fast_immutable_collections.dart";
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
    required String eventId,
    @JsonKey(name: "sender") required String authorId,
    required String type,
    String? stateKey,
    @EpochDateTimeConverter() required DateTime timestamp,
    required IMap<String, dynamic> content,
    IMap<String, dynamic>? decrypted,
    String? decryptedType,
    @Default(IMap.empty()) IMap<String, dynamic> unsigned,
    LocalContent? localContent,
    String? transactionId,
    String? redactedBy,
    String? relatesTo,
    String? relationType,
    String? decryptionError,
    String? sendError,
    @Default(IMap.empty()) IMap<String, int> reactions,
    int? lastEditRowId,
    @UnreadTypeConverter() UnreadType? unreadType,
  }) = _Event;

  factory Event.fromJson(Map<String, Object?> json) => _$EventFromJson(json);
}

@freezed
abstract class LocalContent with _$LocalContent {
  const factory LocalContent({
    String? sanitizedHtml,
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
