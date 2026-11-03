import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/bot_command_description.dart";

part "bot_command.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const BotCommand({
  required final String sender,
  required final String botName,
  final Uri? botAvatar,
  required final BotCommandDescriptionContent description,
}) with _$BotCommand {
  /// Commands gomuks handles itself, which bots can't override.
  static const builtIn = ISetConst({
    "me",
    "notice",
    "timestamp",
    "unencrypted",
    "rawinputbody",
    "rainbow",
    "plain",
    "html",
    "htmlmd",
  });

  static const gomuksSender = "@gomuks";

  String get prefix => "/${description.command}";
  String get about => [botName, ?description.description].join(" · ");

  bool completes(String text) =>
      text.startsWith("/") &&
      (prefix.startsWith(text) || argumentsIn(text) != null);

  String? argumentsIn(String text) =>
      text.startsWith("$prefix ") ? text.substring(prefix.length + 1) : null;
}
