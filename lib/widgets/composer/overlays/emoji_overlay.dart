import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/all_emoji.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/image_pack.dart";

class const EmojiOverlay(
  final String query, {
  required final String roomId,
  required final void Function({required String id, required String name})
  addTag,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(AllEmojiController.provider(roomId))
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
                  leading: SizedBox.square(
                    dimension: 28,
                    child: FittedBox(child: emoji.widget),
                  ),
                  title: Text(emoji.aliases.first),
                  subtitle: Text(emoji.description),
                  onTap: () => addTag(
                    id: emoji.value.startsWith("mxc://")
                        ? ImagePack.emojiMarkdown(
                            emoji.aliases.first,
                            emoji.value,
                          )
                        : emoji.value,
                    name: emoji.aliases.first,
                  ),
                ),
              )
              .toList(),
        ),
      );
}
