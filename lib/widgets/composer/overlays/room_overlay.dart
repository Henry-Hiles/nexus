import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class const RoomOverlay(
  final String roomId, {
  required final String query,
  required final void Function({required String id, required String name})
  addTag,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(RoomsController.provider);
    return ListView(
      children:
          (query.isEmpty
                  ? rooms.values
                  : rooms.values.where(
                      (room) => (room.metadata?.name ?? room.metadata?.id ?? "")
                          .toLowerCase()
                          .contains(query.toLowerCase()),
                    ))
              .map((room) {
                final name =
                    room.metadata?.name ??
                    room.metadata?.canonicalAlias ??
                    room.metadata?.id ??
                    "Unknown Room";
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
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
                      final vias = ref.watch(ViaController.provider(room));
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
                  ),
                );
              })
              .toList(),
    );
  }
}
