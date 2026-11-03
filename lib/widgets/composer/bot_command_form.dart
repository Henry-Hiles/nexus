import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/widgets/composer/bot_option_pill.dart";

/// A bot command with its parameters filled in inline, like Discord's slash
/// commands.
class const BotCommandForm(
  final BotCommandDraft draft, {
  required final VoidCallback onSubmit,

  /// Called on backspace in the first parameter while empty.
  required final VoidCallback onRemove,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: .center,
      children: [
        Text(
          draft.command.prefix,
          style: .new(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: .bold,
          ),
        ),
        ...draft.shown.mapIndexed(
          (index, parameter) => BotOptionPill(
            parameter,
            key: ValueKey(parameter.key),
            roomId: draft.roomId,
            onSubmit: onSubmit,
            onRemove: parameter.optional
                ? () => ref
                      .read(
                        BotCommandDraftController.provider(draft.roomId)
                            .notifier,
                      )
                      .removeOption(parameter.key)
                : index == 0
                ? onRemove
                : null,
          ),
        ),
      ],
    );
  }
}
