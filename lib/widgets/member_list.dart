import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/avatar_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MemberList extends ConsumerWidget {
  final Room room;
  const MemberList(this.room, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: SizedBox(
      width: 240,
      child: ref
          .watch(MembersController.provider(room))
          .betterWhen(
            data: (members) => ListView(
              children: [
                ...members
                    .where(
                      (membership) =>
                          membership.content["membership"] ==
                          Membership.join.name,
                    )
                    .map(
                      (member) => ListTile(
                        leading: AvatarOrHash(
                          ref
                              .watch(
                                AvatarController.provider(
                                  member.content["avatar_url"].toString(),
                                ),
                              )
                              .whenOrNull(data: (data) => data),
                          member.content["displayname"].toString(),
                          headers: room.client.headers,
                        ),
                        title: Text(
                          member.content["displayname"].toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              ],
            ),
          ),
    ),
  );
}
