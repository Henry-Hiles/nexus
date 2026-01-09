import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/avatar_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/loading.dart";

class MentionOverlay extends ConsumerWidget {
  final String? triggerCharacter;
  final String query;
  final Room room;
  final void Function({required String id, required String name}) addTag;
  const MentionOverlay(
    this.room, {
    required this.query,
    required this.addTag,
    required this.triggerCharacter,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: EdgeInsets.all(8),
    child: ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        padding: EdgeInsets.all(8),
        child: switch (triggerCharacter) {
          "@" =>
            ref
                .watch(MembersController.provider(room))
                .betterWhen(
                  data: (members) => ListView(
                    children:
                        (query.isEmpty
                                ? members
                                : members.where(
                                    (member) =>
                                        member.senderId.toLowerCase().contains(
                                          query.toLowerCase(),
                                        ) ||
                                        (member.content["displayname"]
                                                    as String?)
                                                ?.toLowerCase()
                                                .contains(
                                                  query.toLowerCase(),
                                                ) ==
                                            true,
                                  ))
                            .map(
                              (member) => ListTile(
                                leading: AvatarOrHash(
                                  ref
                                      .watch(
                                        AvatarController.provider(
                                          member.content["avatar_url"]
                                              .toString(),
                                        ),
                                      )
                                      .whenOrNull(data: (data) => data),
                                  member.content["displayname"].toString(),
                                  headers: room.client.headers,
                                ),
                                title: Text(
                                  member.content["displayname"] as String? ??
                                      member.senderId,
                                ),
                                onTap: () => addTag(
                                  id: member.senderId,
                                  name: member.senderId
                                      .substring(1)
                                      .split(":")
                                      .first,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
          "#" =>
            ref
                .watch(RoomsController.provider)
                .betterWhen(
                  data: (rooms) => ListView(
                    children:
                        (query.isEmpty
                                ? rooms
                                : rooms.where(
                                    (room) => room.title.toLowerCase().contains(
                                      query.toLowerCase(),
                                    ),
                                  ))
                            .map(
                              (room) => ListTile(
                                leading: AvatarOrHash(
                                  room.avatar,
                                  room.title,
                                  fallback: Icon(Icons.numbers),
                                  headers: room.roomData.client.headers,
                                ),
                                title: Text(room.title),
                                subtitle: room.roomData.topic.isEmpty
                                    ? null
                                    : Text(room.roomData.topic, maxLines: 1),
                                onTap: () => addTag(
                                  id: "[#${room.roomData.getLocalizedDisplayname()}](https://matrix.to/#/${room.roomData.id})",
                                  name:
                                      (room.roomData.canonicalAlias.isEmpty
                                              ? room.roomData.id
                                              : room.roomData.canonicalAlias)
                                          .substring(1)
                                          .split(":")
                                          .first,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
          _ => Loading(),
        },
      ),
    ),
  );
}
