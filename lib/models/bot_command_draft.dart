import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/content/bot_command.dart";
import "package:nexus/models/content/bot_command_description.dart";

part "bot_command_draft.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const BotCommandDraft({
  required final BotCommand command,
  required final String roomId,
  final IMap<String, String> texts = const .empty(),

  // The servers to join rooms picked from suggestions through, by room ID
  final IMap<String, IList<String>> vias = const .empty(),
  final ISet<String> options = const .empty(),
  final String? focused,
}) with _$BotCommandDraft {
  IList<BotParameter> get shown => command.description.parameters
      .where(
        (parameter) => !parameter.optional || options.contains(parameter.key),
      )
      .toIList();

  IList<BotParameter> get hiddenOptions => command.description.parameters
      .where(
        (parameter) => parameter.optional && !options.contains(parameter.key),
      )
      .toIList();

  BotParameter? get focusedParameter => command.description.parameters
      .firstWhereOrNull((parameter) => parameter.key == focused);

  ({Object? value, String? error}) parse(BotParameter parameter) =>
      parameter.schema.parseText(texts[parameter.key] ?? "", roomId: roomId);

  IMap<String, Object> get arguments => .fromEntries(
    shown
        .map(
          (parameter) => switch (parse(parameter).value) {
            final value? => MapEntry(parameter.key, withVias(value)),
            null => null,
          },
        )
        .nonNulls,
  );

  IMap<String, String> get errors => .fromEntries(
    shown
        .map(
          (parameter) => switch (parse(parameter).error) {
            final error? => MapEntry(parameter.key, error),
            null => null,
          },
        )
        .nonNulls,
  );

  IList<BotParameter> get missing => shown
      .where(
        (parameter) => !parameter.optional && parse(parameter).value == null,
      )
      .toIList();

  String? get problem => errors.isNotEmpty
      ? errors.entries.map((error) => "${error.key}: ${error.value}").join("\n")
      : missing.isNotEmpty
      ? "Fill in ${missing.map((parameter) => parameter.key).join(", ")} first."
      : null;

  BotCommandInput get input =>
      .new(command: command.description.command, arguments: arguments);

  String get body => [
    command.prefix,
    ...shown
        .map(
          (parameter) => switch (texts[parameter.key]
              ?.split(BotParameterSchema.separator)
              .where((part) => part.isNotEmpty)
              .join(" ")) {
            final text? when text.isEmpty => null,
            final text? when parameter.optional => "--${parameter.key} $text",
            final text => text,
          },
        )
        .nonNulls,
  ].join(" ");

  Object withVias(Object value) => switch (value) {
    List() => value.whereType<Object>().map(withVias).toList(),
    final Map<String, Object> room && {"type": "room_id", "id": final String id}
        when !room.containsKey("via") =>
      switch (vias[id]) {
        final via? => {...room, "via": via.unlock},
        null => room,
      },
    _ => value,
  };
}
