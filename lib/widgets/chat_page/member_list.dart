import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/avatar_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MemberList extends ConsumerWidget {
  final Room room;
  const MemberList(this.room, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    shape: Border(),
    child: ref
        .watch(MembersController.provider(room))
        .betterWhen(
          data: (members) => ListView(
            children: [
              AppBar(
                scrolledUnderElevation: 0,
                leading: Icon(Icons.people),
                title: Text("Members"),
                actionsPadding: EdgeInsets.only(right: 4),
                actions: [
                  if (Scaffold.of(context).hasEndDrawer)
                    IconButton(
                      onPressed: Scaffold.of(context).closeEndDrawer,
                      icon: Icon(Icons.close),
                    ),
                ],
              ),
              ...members
                  .where(
                    (membership) =>
                        membership.content["membership"] ==
                        Membership.join.name,
                  )
                  .map(
                    (member) => ListTile(
                      onTap: () {},
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
  );
}
