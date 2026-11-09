import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/controllers/bot_argument_suggestions.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/models/bot_argument_suggestion.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/text_command.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";

class const BotCommandPanel(
  final ComposerParams composer, {
  required final IList<BotCommand> commands,
  required final IList<TextCommand> textCommands,
  required final TextEditingController controller,
  required final void Function(BotCommand command) onPick,
  required final void Function(TextCommand command) onPickText,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draftProvider = BotCommandDraftController.provider(composer);
    final suggestionsProvider = BotArgumentSuggestionsController.provider(
      composer,
    );

    final text = useState(controller.text);
    useEffect(() {
      void update() {
        if (SchedulerBinding.instance.schedulerPhase == .persistentCallbacks) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) text.value = controller.text;
          });
        } else {
          text.value = controller.text;
        }
      }

      controller.addListener(update);
      return () => controller.removeListener(update);
    }, [controller]);

    ListTile commandTile(BotCommand command, {VoidCallback? onTap}) => .new(
      leading: AvatarOrHash(command.botAvatar, command.botName, dimension: 32),
      title: Text(command.prefix),
      subtitle: Text(command.about, maxLines: 1, overflow: .ellipsis),
      onTap: onTap,
    );

    final children = switch (ref.watch(draftProvider)) {
      null => [
        ...textCommands
            .where((command) => command.completes(text.value))
            .map(
              (command) => ListTile(
                leading: AvatarOrHash(null, "gomuks", dimension: 32),
                title: Text(command.prefix),
                subtitle: Text(
                  "gomuks · ${command.description}",
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                onTap: () => onPickText(command),
              ),
            ),
        ...commands
            .where((command) => command.completes(text.value))
            .map(
              (command) => commandTile(command, onTap: () => onPick(command)),
            ),
      ],
      final draft => [
        commandTile(draft.command),
        if (draft.focusedParameter case final parameter?)
          ListTile(
            title: Text(
              parameter.key,
              style: .new(color: theme.colorScheme.primary),
            ),
            subtitle: switch ((
              draft.errors[parameter.key],
              parameter.description,
            )) {
              (final error?, _) => Text(
                error,
                style: .new(color: theme.colorScheme.error),
              ),
              (null, final description?) => Text(description),
              (null, null) => null,
            },
            trailing: Text(
              parameter.schema.label,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ...ref
            .watch(suggestionsProvider)
            .map(
              (suggestion) => ListTile(
                leading: switch (suggestion) {
                  BotArgumentSuggestion(room: _?) => AvatarOrHash(
                    suggestion.avatar,
                    suggestion.title,
                    fallback: Icon(Icons.numbers),
                  ),
                  BotArgumentSuggestion(subtitle: _?) => AvatarOrHash(
                    suggestion.avatar,
                    suggestion.title,
                  ),
                  _ => null,
                },
                title: Text(suggestion.title),
                subtitle: switch (suggestion.subtitle) {
                  final subtitle? => Text(subtitle),
                  null => null,
                },
                onTap: () =>
                    ref.read(suggestionsProvider.notifier).pick(suggestion),
              ),
            ),
        if (draft.hiddenOptions.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: .center,
              children: [
                Text("Optional", style: theme.textTheme.labelMedium),
                ...draft.hiddenOptions.map(
                  (option) => ActionChip(
                    avatar: Icon(Icons.add),
                    label: Text(option.key),
                    tooltip: option.description,
                    onPressed: () =>
                        ref.read(draftProvider.notifier).addOption(option.key),
                  ),
                ),
              ],
            ),
          ),
      ],
    };

    return children.isEmpty
        ? SizedBox(width: double.infinity)
        : TextFieldTapRegion(
            child: Card(
              margin: .only(bottom: 8),
              clipBehavior: .antiAlias,
              child: ConstrainedBox(
                constraints: .new(maxHeight: 320),
                child: ListView(shrinkWrap: true, children: children),
              ),
            ),
          );
  }
}
