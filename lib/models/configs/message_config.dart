import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";
part "message_config.freezed.dart";
part "message_config.g.dart";

@freezed
abstract class MessageConfig with _$MessageConfig {
  const MessageConfig._();
  const factory MessageConfig({
    @Default(false) bool alwaysReturn,
    @Default(false) bool includeEdits,
    required Room room,
    required Event event,
  }) = _MessageConfig;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is MessageConfig &&
      other.event == event;

  @override
  int get hashCode => Object.hash(runtimeType, event);

  factory MessageConfig.fromJson(Map<String, Object?> json) =>
      _$MessageConfigFromJson(json);
}
