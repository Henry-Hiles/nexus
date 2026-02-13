import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/room.dart";
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
                                          member.stateKey
                                                  ?.toLowerCase()
                                                  .contains(
                                                    query.toLowerCase(),
                                                  ) ==
                                              true ||
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
                                    Uri.tryParse(
                                      member.content["avatar_url"] ?? "",
                                    ),
                                    member.content["displayname"] ?? "",
                                  ),
                                  title: Text(
                                    member.content["displayname"] as String? ??
                                        member.stateKey ??
                                        "Unknown User",
                                  ),
                                  subtitle: member.stateKey != null
                                      ? Text(member.stateKey!)
                                      : null,
                                  onTap: () => addTag(
                                    id: "[@${member.content["displayname"]}](https://matrix.to/#/${member.stateKey})",
                                    name:
                                        member.stateKey
                                            ?.substring(1)
                                            .split(":")
                                            .first ??
                                        "Unknown User",
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
