import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/members_by_status.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class const UserOverlay(
  final String query, {
  required final String roomId,
  required final void Function({required String id, required String name})
  addTag,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(
        MembersByStatusController.provider(.new(roomId: roomId, status: .join)),
      )
      .betterWhen(
        data: (members) => ListView(
          children:
              (query.isEmpty
                      ? members
                      : members.where(
                          (member) =>
                              member.stateKey?.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ) ==
                                  true ||
                              switch (member.content) {
                                MembershipContent(:final displayName) =>
                                  displayName?.toLowerCase().contains(
                                        query.toLowerCase(),
                                      ) ==
                                      true,
                                _ => false,
                              },
                        ))
                  .map(
                    (member) => switch (member.content) {
                      MembershipContent(:final displayName, :final avatarUrl) =>
                        ListTile(
                          leading: AvatarOrHash(
                            avatarUrl,
                            displayName ?? member.stateKey!.localpart,
                          ),
                          title: Text(
                            displayName ?? member.stateKey!.localpart,
                          ),
                          subtitle: Text(member.stateKey!),
                          onTap: () => addTag(
                            id: "[@$displayName](matrix:u/${member.stateKey!.substring(1)})",
                            name: member.stateKey!.localpart,
                          ),
                        ),
                      _ => SizedBox.shrink(),
                    },
                  )
                  .toList(),
        ),
      );
}
