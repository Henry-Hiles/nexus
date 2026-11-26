import "dart:io";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:file_selector/file_selector.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/attachment.dart";
import "package:nexus/controllers/composer_draft.dart";
import "package:nexus/controllers/sidebar_page.dart";
import "package:nexus/controllers/spaces.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/get_all_child_rooms.dart";
import "package:nexus/helpers/extensions/weighted_search.dart";
import "package:nexus/main.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";

class const ShareSheet(final IList<SharedMediaFile> files, {super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useValueListenable(controller).text;
    final spaces = ref.watch(SpacesController.provider).value ?? const .empty();

    final rooms =
        IMap.fromEntries(
              spaces
                  .expand((space) => space.allChildRooms)
                  .map((room) => room.metadata)
                  .nonNulls
                  .map((room) => MapEntry(room.id, room)),
            ).values
            .sortedBy((room) => room.sortingTimestamp)
            .reversed
            .search(
              query,
              (room) => [(room.name, 2), (room.canonicalAlias, 1)],
            );

    bool isText(SharedMediaFile file) =>
        file.type == .url ||
        (file.type == .text && !File(file.path).existsSync());

    final text = files.where(isText).map((file) => file.path).join("\n");
    final file = files.firstWhereOrNull((file) => !isText(file));

    Future<void> shareTo(String roomId) async {
      final container = ProviderScope.containerOf(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      await container.focusRoom(roomId);
      container.read(SidebarPageController.provider.notifier).set(.rooms);

      final ComposerParams composer = (roomId: roomId, threadRoot: null);
      final draftProvider = ComposerDraftController.provider(composer);
      // Shares go in a new message, not an edit
      if (container.read(draftProvider).isEditing) {
        container.read(draftProvider.notifier).dismiss();
      }

      if (text.isNotEmpty) {
        container
            .read(draftProvider.notifier)
            .update(
              (draft) => draft.copyWith(
                text: draft.text.isEmpty ? text : "${draft.text}\n$text",
                textReplacements: draft.textReplacements + 1,
              ),
            );
      }

      if (file != null) {
        await container
            .read(
              AttachmentController.provider((
                composer: composer,
                editingRowId: null,
              )).notifier,
            )
            .add(XFile(file.path));
      }
    }

    return SheetLayout(
      title: Text(switch ((file, text.isNotEmpty)) {
        (_?, _) => "Share File",
        (null, true) => "Share Text",
        (null, false) => "Share",
      }),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
      ],
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          decoration: .new(
            hintText: "Search rooms",
            prefixIcon: Icon(Icons.search),
          ),
        ),
        if (rooms.isEmpty)
          Text("No rooms found")
        else
          Column(
            children: rooms
                .map(
                  (room) => ListTile(
                    leading: AvatarOrHash(
                      room.avatar,
                      room.name ?? "Unnamed Room",
                      fallback: room.dmUserId == null
                          ? Icon(Icons.numbers)
                          : null,
                    ),
                    title: Text(
                      room.name ?? "Unnamed Room",
                      overflow: .ellipsis,
                    ),
                    onTap: () => shareTo(room.id).onError(showError),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
