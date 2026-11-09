import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/helpers/extensions/weighted_search.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";

class const RoomOverlay(
  final String query, {
  required final void Function({required String id, required String name})
  addTag,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(RoomsController.provider);
    return ListView(
      children: rooms.values
          .search(
            query,
            (room) => [
              (room.metadata?.name, 3),
              (room.metadata?.canonicalAlias, 2),
              (room.metadata?.id, 1),
            ],
          )
          .map((room) {
            final name =
                room.metadata?.name ??
                room.metadata?.canonicalAlias ??
                room.metadata?.id ??
                "Unknown Room";
            return ListTile(
              leading: AvatarOrHash(
                room.metadata?.avatar,
                name,
                fallback: Icon(Icons.numbers),
              ),
              title: Text(name),
              subtitle: room.metadata?.topic == null
                  ? null
                  : Text(room.metadata!.topic!, maxLines: 1),
              onTap: () {
                final vias = ref.watch(ViaController.provider(room)).viaQuery;
                addTag(
                  id: "[#$name](matrix:roomid/${room.metadata?.id.substring(1)}$vias)",
                  name:
                      (room.metadata?.canonicalAlias ?? room.metadata?.id)
                          ?.substring(1)
                          .split(":")
                          .first ??
                      "",
                );
              },
            );
          })
          .toList(),
    );
  }
}
