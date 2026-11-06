import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/bot_argument_suggestion.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/content/bot_command_description.dart";

class BotCommandDraftController(final ComposerParams composer)
    extends Notifier<BotCommandDraft?> {
  @override
  BotCommandDraft? build() => null;

  void start(BotCommand command, {String text = ""}) {
    state = BotCommandDraft(
      command: command,
      composer: composer,
      texts: .fromEntries(
        command.description.parameters
            .where((parameter) => !parameter.optional)
            .map(
              (parameter) => switch (parameter.schema) {
                LiteralSchema(:final value) => MapEntry(
                  parameter.key,
                  "$value",
                ),
                _ => null,
              },
            )
            .nonNulls,
      ),
    );
    focusNext();
    if (state?.focused case final key? when text.isNotEmpty) setText(key, text);
  }

  void setText(String key, String text) {
    if (state case final draft?) {
      state = draft.copyWith(texts: draft.texts.add(key, text));
    }
  }

  void focus(String key) => state = state?.copyWith(focused: key);

  void focusNext() {
    if (state case final draft?) {
      state = draft.copyWith(
        focused: draft.missing.firstOrNull?.key ?? draft.focused,
      );
    }
  }

  void addOption(String key) {
    if (state case final draft?) {
      state = draft.copyWith(options: draft.options.add(key), focused: key);
    }
  }

  void removeOption(String key) {
    if (state case final draft?) {
      state = draft.copyWith(
        options: draft.options.remove(key),
        texts: draft.texts.remove(key),
        // Focus moves back a parameter if none are missing, so it isn't lost
        focused: draft.focused == key
            ? draft.missing.firstOrNull?.key ??
                  draft.shown
                      .takeWhile((parameter) => parameter.key != key)
                      .lastOrNull
                      ?.key
            : draft.focused,
      );
    }
  }

  void pick(BotArgumentSuggestion suggestion, {required ISet<String> via}) {
    if (state case BotCommandDraft(
      focusedParameter: final parameter?,
      :final texts,
      :final vias,
    )) {
      final text = texts[parameter.key] ?? "";
      final isArray = parameter.schema is ArraySchema;
      state = state?.copyWith(
        texts: texts.add(
          parameter.key,
          isArray
              ? "${text.substring(0, text.lastIndexOf(BotParameterSchema.separator) + 1)}${suggestion.text}, "
              : suggestion.text,
        ),
        vias: via.isEmpty ? vias : vias.add(suggestion.text, via.toIList()),
      );
      if (!isArray) focusNext();
    }
  }

  void clear() => state = null;

  static final provider = NotifierProvider.autoDispose
      .family<BotCommandDraftController, BotCommandDraft?, ComposerParams>(
        BotCommandDraftController.new,
      );
}
