import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:nexus/controllers/members_by_status_controller.dart";
import "package:nexus/controllers/members_grouped_controller.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";

class MemberList extends HookConsumerWidget {
  final String roomId;
  const MemberList(this.roomId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusIndex = useState(0);

    final options = <String, MembershipStatus>{
      "Joined": .join,
      "Invited": .invite,
      "Banned": .ban,
    };
    final status = options.values.toIList()[statusIndex.value];

    return Drawer(
      shape: Border(),
      child: Column(
        children: [
          AppBar(
            scrolledUnderElevation: 0,
            leading: Icon(Icons.people),
            title: Text("Members"),
            actionsPadding: .only(right: 4),
            actions: [
              if (Scaffold.of(context).hasEndDrawer)
                IconButton(
                  onPressed: Scaffold.of(context).closeEndDrawer,
                  icon: Icon(Icons.close),
                  tooltip: "Close member list",
                ),
            ],
          ),
          Padding(
            padding: .symmetric(vertical: 8),
            child: M3EToggleButtonGroup(
              type: .connected,
              selectedIndex: statusIndex.value,
              onSelectedIndexChanged: (index) =>
                  statusIndex.value = index ?? statusIndex.value,
              actions: options
                  .mapTo(
                    (name, value) => M3EToggleButtonGroupAction(
                      checkedLabel: Text(
                        "$name${switch (ref.watch(MembersByStatusController.provider(.new(roomId: roomId, status: value)))) {
                          AsyncData(:final value) || AsyncLoading(:final value?) => " (${value.length})",
                          _ => "",
                        }}",
                      ),
                      label: Text(name),
                    ),
                  )
                  .toList(),
            ),
          ),

          switch (ref.watch(
            MembersGroupedController.provider(
              .new(roomId: roomId, status: status),
            ),
          )) {
            AsyncError(:final error, :final stackTrace) => ErrorDialog(
              error,
              stackTrace,
            ),
            AsyncData(:final value) || AsyncLoading(:final value?) =>
              value.isEmpty
                  ? Center(
                      child: Padding(
                        padding: .symmetric(vertical: 18),
                        child: Text(
                          "No ${options.keys.toIList()[statusIndex.value]} Members",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    )
                  : Expanded(
                      child: CustomScrollView(
                        slivers: [
                          for (final MapEntry(key: powerLevel, value: members)
                              in value) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: .symmetric(horizontal: 16),
                                child: DividerText(
                                  powerLevel == null
                                      ? "Creators"
                                      : "Power Level $powerLevel",
                                ),
                              ),
                            ),
                            SliverM3ECardList(
                              padding: .all(4),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              margin: .symmetric(horizontal: 12, vertical: 4),
                              itemCount: members.length,
                              itemBuilder: (context, index) =>
                                  switch (members[index].content) {
                                    MembershipContent(
                                      :final avatarUrl,
                                      :final displayName,
                                    ) =>
                                      ListTile(
                                        title: Text(
                                          displayName ??
                                              members[index]
                                                  .stateKey!
                                                  .localpart,
                                          overflow: .ellipsis,
                                          style: .new(
                                            color: members[index]
                                                .stateKey!
                                                .colorHash,
                                            fontWeight: .bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          members[index].stateKey!,
                                          overflow: .ellipsis,
                                        ),
                                        leading: AvatarOrHash(
                                          avatarUrl,
                                          displayName ??
                                              members[index].sender.localpart,
                                        ),
                                      ),
                                    _ => throw Exception(
                                      "Member content was not MembershipContent",
                                    ),
                                  },
                              onTap: (index) {
                                //  context.showUserPopover(
                                //   member.content as MembershipContent,
                                //   member.stateKey!,
                                //   roomId: roomId,
                                //   globalPosition: details.globalPosition,
                                // ),
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            AsyncLoading _ => Loading(),
          },
        ],
      ),
    );
  }
}
