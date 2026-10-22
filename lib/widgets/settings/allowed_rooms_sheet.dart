import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Chooses the rooms whose members can join [roomId] without an invite.
class const AllowedRoomsSheet({
  required final String roomId,
  required final ISet<String> allowed,

  /// Suggested first, as they're the usual choice.
  required final ISet<String> parentSpaces,
  required final void Function(ISet<String> allowed) onSave,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = useState(allowed);
    final error = useState<String?>(null);
    final resolving = useState(false);
    final controller = useTextEditingController();
    final query = useValueListenable(controller).text.trim().toLowerCase();
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
    Widget avatarOf(String id) => AvatarOrHash(
      rooms[id]?.avatar,
      nameOf(id),
      fallback: Icon(Icons.numbers),
    );
    String? subtitleOf(String id) => parentSpaces.contains(id)
        ? "Parent space"
        : rooms[id]?.name == null
        ? null
        : id;

    final suggestions = parentSpaces
        .addAll(
          rooms.entries
              .where((entry) => !parentSpaces.contains(entry.key))
              .sortedBy((entry) => entry.value.name?.toLowerCase() ?? "")
              .map((entry) => entry.key),
        )
        .where((id) => id != roomId)
        .toISet();
    final shown = suggestions
        .where(
          (id) =>
              !chosen.value.contains(id) &&
              (nameOf(id).toLowerCase().contains(query) ||
                  id.toLowerCase().contains(query)),
        )
        .toISet();

    void add(String id) {
      if (id == roomId) {
        error.value = "A room can't allow itself";
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

    return SheetLayout(
      title: Text("Allowed Rooms"),
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
        Text("Members of these rooms can join without an invite."),
        if (chosen.value.isEmpty)
          Text("None, so only invited users can join")
        else
          Column(
            children: chosen.value
                .map(
                  (id) => ListTile(
                    leading: avatarOf(id),
                    title: Text(nameOf(id), overflow: .ellipsis),
                    subtitle: switch (subtitleOf(id)) {
                      final subtitle? => Text(subtitle, overflow: .ellipsis),
                      null => null,
                    },
                    trailing: IconButton(
                      tooltip: "Remove room",
                      icon: Icon(Icons.delete),
                      onPressed: () => chosen.value = chosen.value.remove(id),
                    ),
                  ),
                )
                .toList(),
          ),
        TextField(
          controller: controller,
          enabled: !resolving.value,
          onChanged: (_) => error.value = null,
          onSubmitted: (text) {
            final trimmed = text.trim();
            if (trimmed.isEmpty) return;

            if (trimmed.startsWith(RegExp("[!#]"))) {
              addRoom(trimmed).onError(showError);
            } else if (shown.firstOrNull case final id?) {
              add(id);
            } else {
              error.value = "Enter a room ID or alias";
            }
          },
          decoration: .new(
            labelText: "Add room",
            hintText: "Search, or enter a room ID or alias",
            errorText: error.value,
            suffixIcon: resolving.value
                ? Padding(
                    padding: .all(12),
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : null,
          ),
        ),
        AnimatedSize(
          duration: Durations.short2,
          alignment: .topCenter,
          child: shown.isEmpty
              ? SizedBox(width: .infinity)
              : Material(
                  elevation: 4,
                  borderRadius: .circular(12),
                  clipBehavior: .antiAlias,
                  child: ConstrainedBox(
                    constraints: const .new(maxHeight: 240),
                    child: ListView.builder(
                      padding: .zero,
                      shrinkWrap: true,
                      itemExtent: 72,
                      itemCount: shown.length,
                      itemBuilder: (context, index) {
                        final id = shown[index];
                        return ListTile(
                          leading: avatarOf(id),
                          title: Text(nameOf(id), overflow: .ellipsis),
                          subtitle: switch (subtitleOf(id)) {
                            final subtitle? => Text(
                              subtitle,
                              overflow: .ellipsis,
                            ),
                            null => null,
                          },
                          onTap: () => add(id),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
