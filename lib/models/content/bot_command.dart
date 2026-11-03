import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";

part "bot_command.freezed.dart";
part "bot_command.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const BotCommandMessageContent({
  required final String body,
  @JsonKey(name: "org.matrix.msc4391.command")
  required final BotCommandInput command,
  final String msgtype = "m.text",
}) extends Content with _$BotCommandMessageContent {
  @override
  Map<String, Object?> toJson() => _$BotCommandMessageContentToJson(this);

  factory BotCommandMessageContent.fromJson(Map<String, Object?> json) =>
      _$BotCommandMessageContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const BotCommandInput({
  required final String command,
  final IMap<String, Object> arguments = const .empty(),
}) with _$BotCommandInput {
  Map<String, Object?> toJson() => _$BotCommandInputToJson(this);

  factory BotCommandInput.fromJson(Map<String, Object?> json) =>
      _$BotCommandInputFromJson(json);
}
