import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MemberList extends ConsumerWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersProvider = ref.watch(MembersController.provider);
    return Drawer(
      shape: Border(),
      child: Column(
        children: [
          AppBar(
            scrolledUnderElevation: 0,
            leading: Icon(Icons.people),
            title: Text(
              "Members ${membersProvider.when(data: (members) => "${members.length}", error: (_, _) => "", loading: () => "")}",
            ),
            actionsPadding: EdgeInsets.only(right: 4),
            actions: [
              if (Scaffold.of(context).hasEndDrawer)
                IconButton(
                  onPressed: Scaffold.of(context).closeEndDrawer,
                  icon: Icon(Icons.close),
                  tooltip: "Close member list",
                ),
            ],
          ),
          membersProvider.betterWhen(
            data: (members) => Expanded(
              child: ListView(
                children: members
                    .map(
                      (member) => InkWell(
                        onTapDown: (details) => context.showUserPopover(
                          member,
                          globalPosition: details.globalPosition,
                        ),
                        child: ListTile(
                          leading: AvatarOrHash(
                            member.avatarUrl,
                            member.displayName,
                          ),
                          title: Text(
                            member.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            member.userId,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
