import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_type_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/loading.dart";

class MentionOverlay extends ConsumerWidget {
  final String? triggerCharacter;
  final String query;
  final void Function({required String id, required String name}) addTag;
  const MentionOverlay({
    required this.query,
    required this.addTag,
    required this.triggerCharacter,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(RoomsController.provider);

    return Padding(
      padding: EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          padding: EdgeInsets.all(8),
          child: switch (triggerCharacter) {
            "@" =>
              ref
                  .watch(
                    MembersByTypeController.provider(MembershipStatus.join),
                  )
                  .betterWhen(
                    data: (members) => ListView(
                      children:
                          (query.isEmpty
                                  ? members
                                  : members.where(
                                      (member) =>
                                          member.userId.toLowerCase().contains(
                                                query.toLowerCase(),
                                              ) ==
                                              true ||
                                          member.displayName
                                                  .toLowerCase()
                                                  .contains(
                                                    query.toLowerCase(),
                                                  ) ==
                                              true,
                                    ))
                              .map(
                                (member) => ListTile(
                                  leading: AvatarOrHash(
                                    member.avatarUrl,
                                    member.displayName,
                                  ),
                                  title: Text(member.displayName),
                                  subtitle: Text(member.userId),
                                  onTap: () => addTag(
                                    id: "[@${member.displayName}](https://matrix.to/#/${member.userId})",
                                    name: member.userId
                                        .substring(1)
                                        .split(":")
                                        .first,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
            "#" => ListView(
              children:
                  (query.isEmpty
                          ? rooms.values
                          : rooms.values.where(
                              (room) => (room.metadata?.name ?? "Unnamed Room")
                                  .toLowerCase()
                                  .contains(query.toLowerCase()),
                            ))
                      .map(
                        (room) => ListTile(
                          leading: AvatarOrHash(
                            room.metadata?.avatar,
                            room.metadata?.name ?? "Unnamed Room",
                            fallback: Icon(Icons.numbers),
                          ),
                          title: Text(room.metadata?.name ?? "Unnamed Room"),
                          subtitle: room.metadata?.topic == null
                              ? null
                              : Text(room.metadata!.topic!, maxLines: 1),
                          onTap: () => addTag(
                            // Should add vias to generated link, see following:
                            // https://github.com/gomuks/gomuks/blob/d5deeb5d409181e469eada8b534882576ac78e63/web/src/ui/modal/ShareModal.tsx#L31-L57
                            // https://github.com/gomuks/gomuks/blob/main/web/src/api/statestore/room.ts#L329
                            id: "[#${room.metadata?.name ?? "Unnamed Room"}](https://matrix.to/#/${room.metadata?.canonicalAlias ?? room.metadata?.id})",
                            name:
                                (room.metadata?.canonicalAlias ??
                                        room.metadata?.id)
                                    ?.substring(1)
                                    .split(":")
                                    .first ??
                                "",
                          ),
                        ),
                      )
                      .toList(),
            ),

            _ => Loading(),
          },
        ),
      ),
    );
  }
}
