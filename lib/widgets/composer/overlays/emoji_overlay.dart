import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_emoji_picker/material_emoji_picker.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/better_when.dart";

class const EmojiOverlay(
  final String query, {
  required final String roomId,
  required final void Function({required String id, required String name})
  addTag,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(EmojiController.provider)
      .betterWhen(
        data: (emojis) => ListView(
          children: emojis
              .map((element) => element.emojis)
              .flattened
              .where(
                (emoji) =>
                    emoji.aliases.join().contains(query) ||
                    emoji.description.contains(query) ||
                    emoji.tags.join().contains(query),
              )
              .map(
                (emoji) => ListTile(
                  leading: emoji.widget,
                  title: Text(emoji.aliases.first),
                  subtitle: Text(emoji.description),
                  onTap: () => addTag(
                    id: Uri.tryParse(emoji.value)?.scheme == "mxc"
                        ? "" // TODO: Handle custom emotes
                        : emoji.value,
                    name: emoji.aliases.first,
                  ),
                ),
              )
              .toList(),
        ),
      );
}
