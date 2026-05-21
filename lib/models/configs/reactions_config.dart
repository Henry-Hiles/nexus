import "package:freezed_annotation/freezed_annotation.dart";
part "reactions_config.freezed.dart";
part "reactions_config.g.dart";

@freezed
abstract class ReactionsConfig with _$ReactionsConfig {
  const factory ReactionsConfig({
    required String roomId,
    required int eventRowId,
  }) = _ReactionsConfig;

  factory ReactionsConfig.fromJson(Map<String, Object?> json) =>
      _$ReactionsConfigFromJson(json);
}
