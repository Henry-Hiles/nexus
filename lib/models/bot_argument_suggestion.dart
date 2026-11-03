import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";

part "bot_argument_suggestion.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const BotArgumentSuggestion({
  required final String title,
  final String? subtitle,
  final Uri? avatar,
  required final String text,
  final Room? room,
}) with _$BotArgumentSuggestion;
