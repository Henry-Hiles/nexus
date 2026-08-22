import "package:freezed_annotation/freezed_annotation.dart";

part "reactions.freezed.dart";
part "reactions.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const ReactionsConfig({
  required final String roomId,
  required final int eventRowId,
}) with _$ReactionsConfig {
  Map<String, Object?> toJson() => _$ReactionsConfigToJson(this);

  factory ReactionsConfig.fromJson(Map<String, Object?> json) =>
      _$ReactionsConfigFromJson(json);
}
