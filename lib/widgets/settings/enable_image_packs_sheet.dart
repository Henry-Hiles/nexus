import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_image_packs.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/account_data.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/image_pack_avatar.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Chooses a room, then which of its image packs to use in every room.
class const EnableImagePacksSheet({
  required final ImagePackRooms enabled,
  required final void Function(ImagePackRooms enabled) onSave,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = useState(enabled);
    final roomId = useState<String?>(null);
    final rooms = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms.values
            .map((room) => room.metadata)
            .nonNulls
            .map(
              (metadata) => (
                id: metadata.id,
                name: metadata.name ?? metadata.id,
                avatar: metadata.avatar,
              ),
            )
            .sortedBy((room) => room.name.toLowerCase())
            .toIList(),
      ),
    );

    return SheetLayout(
      title: Text("Add Image Packs"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave(chosen.value);
          },
          child: Text("Save"),
        ),
      ],
      children: [
        Text("Packs you add can be used in every room."),
        DropdownMenu(
          expandedInsets: .zero,
          menuHeight: 300,
          enableFilter: true,
          requestFocusOnTap: true,
          label: Text("Room"),
          onSelected: (id) => roomId.value = id,
          dropdownMenuEntries: rooms
              .map(
                (room) => DropdownMenuEntry(
                  value: room.id,
                  label: room.name,
                  leadingIcon: AvatarOrHash(
                    room.avatar,
                    room.name,
                    fallback: Icon(Icons.numbers),
                  ),
                ),
              )
              .toList(),
        ),
        AnimatedSize(
          duration: Durations.medium2,
          curve: Curves.easeInOut,
          alignment: .topCenter,
          child: switch (roomId.value) {
            final roomId? =>
              ref
                  .watch(RoomImagePacksController.provider(roomId))
                  .betterWhen(
                    data: (packs) => packs.isEmpty
                        ? Text("This room has no image packs")
                        : Column(
                            mainAxisSize: .min,
                            children: packs.entries
                                .map(
                                  (entry) => CheckboxListTile(
                                    secondary: ImagePackAvatar(
                                      entry.value.icon,
                                    ),
                                    title: Text(entry.value.name),
                                    subtitle: Text(entry.value.imageCountLabel),
                                    value: chosen.value.contains(
                                      roomId,
                                      entry.key,
                                    ),
                                    onChanged: (value) =>
                                        chosen.value = chosen.value.withPack(
                                          roomId,
                                          entry.key,
                                          enabled: value ?? false,
                                        ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
            null => const SizedBox(width: .infinity),
          },
        ),
      ],
    );
  }
}
