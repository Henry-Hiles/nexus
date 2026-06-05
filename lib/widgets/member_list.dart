import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_segmented_list/material_segmented_list.dart";
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
    final status = useState(MembershipStatus.join);

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
          Wrap(
            alignment: .center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text("Joined"),
                onSelected: (value) => status.value = .join,
                selected: status.value == .join,
              ),
              FilterChip(
                label: Text("Invited"),
                onSelected: (value) => status.value = .invite,
                selected: status.value == .invite,
              ),
              FilterChip(
                label: Text("Banned"),
                onSelected: (value) => status.value = .ban,
                selected: status.value == .ban,
              ),
            ],
          ),
          switch (ref.watch(
            MembersGroupedController.provider(
              .new(roomId: roomId, status: status.value),
            ),
          )) {
            AsyncError(:final error, :final stackTrace) => ErrorDialog(
              error,
              stackTrace,
            ),
            AsyncData(:final value) || AsyncLoading(:final value?) => Expanded(
              child: ListView(
                padding: .all(12),
                children: [
                  for (final MapEntry(key: powerLevel, value: members)
                      in value.toEntryIList(
                        compare: (a, b) => (b?.key ?? double.negativeInfinity)
                            .compareTo(a?.key ?? double.negativeInfinity),
                      )) ...[
                    DividerText("Power Level $powerLevel"),
                    SegmentedListSection(
                      children: members
                          .map(
                            (member) => switch (member.content) {
                              MembershipContent(
                                :final avatarUrl,
                                :final displayName,
                              ) =>
                                SegmentedListTile(
                                  onTap: () {},
                                  //  context.showUserPopover(
                                  //   member.content as MembershipContent,
                                  //   member.stateKey!,
                                  //   roomId: roomId,
                                  //   globalPosition: details.globalPosition,
                                  // ),
                                  title: Text(
                                    displayName ?? member.stateKey!.localpart,
                                    overflow: .ellipsis,
                                    style: .new(
                                      color: member.stateKey!.colorHash,
                                      fontWeight: .bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    member.stateKey!,
                                    overflow: .ellipsis,
                                  ),
                                  leading: AvatarOrHash(
                                    avatarUrl,
                                    displayName ?? member.sender.localpart,
                                  ),
                                ),
                              _ => throw Exception(
                                "Member content was not MembershipContent",
                              ),
                            },
                          )
                          .toList(),
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
