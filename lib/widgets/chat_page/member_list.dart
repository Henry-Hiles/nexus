import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_type_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class MemberList extends HookConsumerWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState(MembershipStatus.join);
    final membersProvider = ref.watch(
      MembersByTypeController.provider(status.value),
    );

    return Drawer(
      shape: Border(),
      child: Column(
        spacing: 8,
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
                  tooltip: "Close member list",
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              FilterChip(
                label: Text("Joined"),
                onSelected: (value) => status.value = MembershipStatus.join,
                selected: status.value == MembershipStatus.join,
              ),
              FilterChip(
                label: Text("Invited"),
                onSelected: (value) => status.value = MembershipStatus.invite,
                selected: status.value == MembershipStatus.invite,
              ),
              FilterChip(
                label: Text("Banned"),
                onSelected: (value) => status.value = MembershipStatus.ban,
                selected: status.value == MembershipStatus.ban,
              ),
            ],
          ),
          membersProvider.betterWhen(
            data: (members) => Expanded(
              child: ListView(
                children: members
                    .map(
                      (member) => InkWell(
                        onTapUp: (details) => context.showUserPopover(
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
