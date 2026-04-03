import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/models/requests/set_membership_request.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/chat_page/expandable_image.dart";

class UserPopover extends ConsumerWidget {
  final Membership member;
  const UserPopover(this.member, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final client = ref.watch(ClientController.provider.notifier);
    final roomId = ref.watch(
      SelectedRoomController.provider.select((room) => room?.metadata?.id),
    );

    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            ExpandableImage(
              member.avatarUrl?.toString(),
              child: AvatarOrHash(
                member.avatarUrl,
                member.displayName,
                height: 80,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  member.displayName,
                  style: textTheme.headlineSmall,
                ),
                SelectableText(member.userId, style: textTheme.titleSmall),
                SizedBox(height: 4),
                ref
                    .watch(ProfileController.provider(member.userId))
                    .betterWhen(
                      loading: SizedBox.shrink,
                      data: (profile) => Wrap(
                        spacing: 4,
                        children: [
                          for (final pronoun in profile.pronouns.where(
                            (pronoun) => pronoun.language == "en",
                          ))
                            Chip(label: Text(pronoun.summary)),
                          if (profile.timezone != null)
                            Chip(label: Text(profile.timezone!)),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ),
        if (member.userId !=
                ref.watch(ClientStateController.provider)?.userId &&
            roomId != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: null, label: Text("Message")),
              FilledButton.icon(
                onPressed: () => client
                    .setMembership(
                      SetMembershipRequest(
                        userId: member.userId,
                        roomId: roomId,
                        action: MembershipAction.kick,
                      ),
                    )
                    .onError(showError),
                label: Text("Kick"),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.error,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.onError,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => client
                    .setMembership(
                      SetMembershipRequest(
                        userId: member.userId,
                        roomId: roomId,
                        action: member.status == MembershipStatus.ban
                            ? MembershipAction.unban
                            : MembershipAction.ban,
                      ),
                    )
                    .onError(showError),
                label: Text(
                  member.status == MembershipStatus.ban ? "Unban" : "Ban",
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.errorContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
