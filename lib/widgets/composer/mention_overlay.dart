import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_status_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/controllers/via_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/configs/members_by_status_config.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/loading.dart";

class MentionOverlay extends ConsumerWidget {
  final String? triggerCharacter;
  final String query;
  final String roomId;
  final void Function({required String id, required String name}) addTag;
  const MentionOverlay(
    this.roomId, {
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
                    MembersByStatusController.provider(
                      MembersByStatusConfig(
                        roomId: roomId,
                        status: MembershipStatus.join,
                      ),
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
                                    ListTile(
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
