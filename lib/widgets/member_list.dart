import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/members_by_status_controller.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/configs/members_by_status_config.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";

class MemberList extends HookConsumerWidget {
  final String roomId;
  const MemberList(this.roomId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState(MembershipStatus.join);
    final membersProvider = ref.watch(
      MembersByStatusController.provider(
        MembersByStatusConfig(roomId: roomId, status: status.value),
      ),
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
          switch (membersProvider) {
            AsyncError(:final error, :final stackTrace) => ErrorDialog(
              error,
              stackTrace,
            ),
            AsyncData(:final value) || AsyncLoading(:final value?) => Expanded(
              child: ListView(
                children: value
                    .map(
                      (member) => switch (member.content) {
                        MembershipContent(
                          :final avatarUrl,
                          :final displayName,
                        ) =>
                          InkWell(
                            onTapUp: (details) => context.showUserPopover(
                              member.content as MembershipContent,
                              member.stateKey!,
                              roomId: roomId,
                              globalPosition: details.globalPosition,
                            ),
                            child: ListTile(
                              leading: AvatarOrHash(
                                avatarUrl,
                                displayName ?? member.sender.localpart,
                              ),
                              title: Text(
                                displayName ?? member.stateKey!.localpart,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: member.stateKey!.colorHash,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                member.stateKey!,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        _ => SizedBox.shrink(),
                      },
                    )
                    .toList(),
              ),
            ),
            AsyncLoading _ => Loading(),
          },
        ],
      ),
    );
  }
}
