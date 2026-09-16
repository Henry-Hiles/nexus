import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/widgets/composer/overlays/room_overlay.dart";
import "package:nexus/widgets/composer/overlays/user_overlay.dart";
import "package:nexus/widgets/composer/overlays/emoji_overlay.dart";
import "package:nexus/widgets/loading.dart";

class const TaggerOverlay(
  final String query, {
  required final String roomId,
  required final void Function({required String id, required String name})
  addTag,
  required final String? triggerCharacter,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: .all(8),
      child: ClipRRect(
        borderRadius: .all(.circular(12)),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          padding: .all(8),
          child: Material(
            color: Colors.transparent,
            child: switch (triggerCharacter) {
              "@" => UserOverlay(query, roomId: roomId, addTag: addTag),
              "#" => RoomOverlay(query, addTag: addTag),
              ":" => EmojiOverlay(query, roomId: roomId, addTag: addTag),

              _ => Loading(),
            },
          ),
        ),
      ),
    );
  }
}
