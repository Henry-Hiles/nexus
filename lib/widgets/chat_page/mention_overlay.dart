import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/room.dart";
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
                  .watch(MembersController.provider(room))
                  .betterWhen(
                    data: (members) => ListView(
                      children:
                          (query.isEmpty
                                  ? members
                                  : members.where(
                                      (member) =>
                                          member.authorId
                                              .toLowerCase()
                                              .contains(query.toLowerCase()) ||
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
                                  // leading: AvatarOrHash( TODO: Images
                                  //   ref
                                  //       .watch(
                                  //         AvatarController.provider(
                                  //           member.content["avatar_url"]
                                  //               .toString(),
                                  //         ),
                                  //       )
                                  //       .whenOrNull(data: (data) => data),
                                  //   member.content["displayname"].toString(),
                                  //   headers: room.client.headers,
                                  // ),
                                  title: Text(
                                    member.content["displayname"] as String? ??
                                        member.authorId,
                                  ),
                                  onTap: () => addTag(
                                    id: "[@${member.content["displayname"]}](https://matrix.to/#/${member.authorId})",
                                    name: member.authorId
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
                          // leading: AvatarOrHash( TODO: Images
                          //   room.avatar,
                          //   room.title,
                          //   fallback: Icon(Icons.numbers),
                          //   headers: room.roomData.client.headers,
                          // ),
                          title: Text(room.metadata?.name ?? "Unnamed Room"),
                          subtitle: room.metadata?.topic == null
                              ? null
                              : Text(room.metadata!.topic!, maxLines: 1),
                          onTap: () => addTag(
                            id: "[#${room.metadata?.name ?? "Unnamed Room"}](https://matrix.to/#/${room.metadata?.id})",
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
