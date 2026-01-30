import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
part "message_config.freezed.dart";
part "message_config.g.dart";

@freezed
abstract class MessageConfig with _$MessageConfig {
  const factory MessageConfig({
    @Default(false) bool mustBeText,
    @Default(false) bool includeEdits,
    required Event event,
  }) = _MessageConfig;

  factory MessageConfig.fromJson(Map<String, Object?> json) =>
      _$MessageConfigFromJson(json);
}
