import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_status.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/loading.dart";

class const MentionOverlay(
  final String roomId, {
  required final String query,
  required final void Function({required String id, required String name})
  addTag,
  required final String? triggerCharacter,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(RoomsController.provider);

    return Padding(
      padding: .all(8),
      child: ClipRRect(
        borderRadius: .all(.circular(12)),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          padding: .all(8),
          child: switch (triggerCharacter) {
            "@" =>
              ref
                  .watch(
                    MembersByStatusController.provider(
                      .new(roomId: roomId, status: .join),
                    ),
                  )
                  .betterWhen(
                    data: (members) => ListView(
                      children:
                          (query.isEmpty
                                  ? members
                                  : members.where(
                                      (member) =>
                                          member.stateKey
                                                  ?.toLowerCase()
                                                  .contains(
                                                    query.toLowerCase(),
                                                  ) ==
                                              true ||
                                          switch (member.content) {
                                            MembershipContent(
                                              :final displayName,
                                            ) =>
                                              displayName
                                                      ?.toLowerCase()
                                                      .contains(
                                                        query.toLowerCase(),
                                                      ) ==
                                                  true,
                                            _ => false,
                                          },
                                    ))
                              .map(
                                (member) => switch (member.content) {
                                  MembershipContent(
                                    :final displayName,
                                    :final avatarUrl,
                                  ) =>
                                    Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        leading: AvatarOrHash(
                                          avatarUrl,
                                          displayName ??
                                              member.stateKey!.localpart,
                                        ),
                                        title: Text(
                                          displayName ??
                                              member.stateKey!.localpart,
                                        ),
                                        subtitle: Text(member.stateKey!),
                                        onTap: () => addTag(
                                          id: "[@$displayName](matrix:u/${member.stateKey!.substring(1)})",
                                          name: member.stateKey!.localpart,
                                        ),
                                      ),
                                    ),
                                  _ => SizedBox.shrink(),
                                },
                              )
                              .toList(),
                    ),
                  ),
            "#" => ListView(
              children:
                  (query.isEmpty
                          ? rooms.values
                          : rooms.values.where(
                              (room) =>
                                  (room.metadata?.name ??
                                          room.metadata?.id ??
                                          "")
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
                              final vias = ref.watch(
                                ViaController.provider(room),
                              );
                              addTag(
                                id: "[#$name](matrix:roomid/${room.metadata?.id.substring(1)}$vias)",
                                name:
                                    (room.metadata?.canonicalAlias ??
                                            room.metadata?.id)
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
            ),

            _ => Loading(),
          },
        ),
      ),
    );
  }
}
