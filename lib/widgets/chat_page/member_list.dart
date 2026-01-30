import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/room.dart";
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
                title: Text("Members (${members.length})"),
                actionsPadding: EdgeInsets.only(right: 4),
                actions: [
                  if (Scaffold.of(context).hasEndDrawer)
                    IconButton(
                      onPressed: Scaffold.of(context).closeEndDrawer,
                      icon: Icon(Icons.close),
                    ),
                ],
              ),
              ...members.map(
                (member) => ListTile(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) =>
                        Dialog(child: Text("TODO: Open member popover")),
                  ),
                  leading: AvatarOrHash(
                    Uri.tryParse(member.content["avatar_url"] ?? ""),
                    member.content["displayname"].toString(),
                  ),
                  title: Text(
                    member.content["displayname"].toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    member.authorId,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}
