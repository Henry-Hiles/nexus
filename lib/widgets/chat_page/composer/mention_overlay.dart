import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_type_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/via_controller.dart";
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
                                    id: "[@${member.displayName}](matrix:u/${member.userId.substring(1)})",
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
                              (room) =>
                                  (room.metadata?.name ?? room.metadata!.id)
                                      .toLowerCase()
                                      .contains(query.toLowerCase()),
                            ))
                      .map((room) {
                        final name =
                            room.metadata?.name ??
                            room.metadata!.canonicalAlias ??
                            room.metadata!.id;
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
