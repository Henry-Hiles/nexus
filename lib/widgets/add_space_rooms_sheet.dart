import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_hierarchy.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/space_child.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/settings/search_chooser.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Chooses rooms to add to the space [spaceId], then adds them.
class const AddSpaceRoomsSheet(
  final String spaceId, {
  required final String spaceName,

  /// The rooms already in the space, which aren't offered.
  required final ISet<String> existing,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = useState(const ISet<String>.empty());
    final error = useState<String?>(null);
    final resolving = useState(false);
    final controller = useTextEditingController();
    final rooms = ref.watch(
      RoomsController.provider.select(
        (rooms) => IMap.fromEntries(
          rooms.values
              .map((room) => room.metadata)
              .nonNulls
              .map(
                (metadata) => MapEntry(metadata.id, (
                  name: metadata.name,
                  avatar: metadata.avatar,
                )),
              ),
        ),
      ),
    );

    String nameOf(String id) => rooms[id]?.name ?? id;

    final suggestions = rooms.entries
        .where((entry) => entry.key != spaceId && !existing.contains(entry.key))
        .sortedBy((entry) => entry.value.name?.toLowerCase() ?? "")
        .map((entry) => entry.key)
        .toIList();

    void add(String id) {
      if (id == spaceId) {
        error.value = "A space can't contain itself";
        return;
      }
      if (existing.contains(id)) {
        error.value = "This room is already in the space";
        return;
      }
      if (!chosen.value.contains(id)) chosen.value = chosen.value.add(id);
      controller.clear();
    }

    Future<void> addRoom(String text) async {
      if (text.startsWith("!")) return add(text);

      resolving.value = true;
      try {
        final id = await ref
            .read(ClientController.provider.notifier)
            .resolveAlias(text);

        if (!context.mounted) return;

        if (id == null) {
          error.value = "No room has this alias";
        } else {
          add(id);
        }
      } finally {
        if (context.mounted) resolving.value = false;
      }
    }

    // Runs after the sheet closes, so it can't use [ref]
    Future<void> save(ProviderContainer container, ISet<String> roomIds) async {
      final client = container.read(ClientController.provider.notifier);
      final joined = container.read(RoomsController.provider);
      final ownServer = container
          .read(ClientStateController.provider)
          ?.userId
          ?.serverName;

      await Future.wait(
        roomIds.map(
          (roomId) => client.setState(
            .new(
              roomId: spaceId,
              type: EventType.spaceChild.type,
              stateKey: roomId,
              content: SpaceChildContent(
                via: switch (joined[roomId]) {
                  final room? => container.read(ViaController.provider(room)),
                  // Rooms the user isn't in can only be routed through their
                  // own server
                  null => ISet([?ownServer]),
                }.toIList(),
              ),
            ),
          ),
        ),
      );
      container.invalidate(SpaceHierarchyController.provider(spaceId));
    }

    return SheetLayout(
      title: Text("Add Rooms"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: chosen.value.isEmpty
              ? null
              : () {
                  final container = ProviderScope.containerOf(context);
                  final roomIds = chosen.value;
                  context.withProgressSnackbar(
                    "Adding ${roomIds.length == 1 ? nameOf(roomIds.single) : "${roomIds.length} rooms"} to $spaceName...",
                    () => save(container, roomIds),
                  );
                  Navigator.of(context).pop();
                },
          child: Text("Add"),
        ),
      ],
      children: [
        Text("Choose rooms to add to \"$spaceName\"."),
        SearchChooser(
          controller: controller,
          chosen: chosen.value,
          options: suggestions,
          nameOf: nameOf,
          avatarOf: (id) => AvatarOrHash(
            rooms[id]?.avatar,
            nameOf(id),
            fallback: Icon(Icons.numbers),
          ),
          subtitleOf: (id) => rooms[id]?.name == null ? null : id,
          onAdded: add,
          onRemoved: (id) => chosen.value = chosen.value.remove(id),
          onSubmitted: (text, topMatch) {
            if (text.startsWith(RegExp("[!#]"))) {
              addRoom(text).onError(showError);
            } else if (topMatch != null) {
              add(topMatch);
            } else {
              error.value = "Enter a room ID or alias";
            }
          },
          onChanged: (_) => error.value = null,
          label: "Add room",
          hint: "Search, or enter a room ID or alias",
          removeTooltip: "Remove room",
          error: error.value,
          loading: resolving.value,
          autofocus: true,
        ),
      ],
    );
  }
}
