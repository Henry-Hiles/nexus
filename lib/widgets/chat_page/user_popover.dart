import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/power_level_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/membership_status.dart";
import "package:nexus/models/requests/membership_action.dart";
import "package:nexus/models/requests/set_membership_request.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/chat_page/expandable_image.dart";
import "package:nexus/widgets/form_text_input.dart";

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

    void showMembershipDialog(MembershipAction action) => showDialog(
      context: context,
      builder: (context) => HookBuilder(
        builder: (context) {
          final actionReasonController = useTextEditingController();
          return AlertDialog(
            title: Text(
              "${toBeginningOfSentenceCase(action.name)} ${member.userId}",
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Are you sure you want to ${action.name} ${member.userId}?",
                ),
                SizedBox(height: 12),
                FormTextInput(
                  required: false,
                  capitalize: true,
                  controller: actionReasonController,
                  title: "Reason for ${action.name} (optional)",
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  client
                      .setMembership(
                        SetMembershipRequest(
                          userId: member.userId,
                          roomId: roomId!,
                          action: action,
                          reason: actionReasonController.text,
                        ),
                      )
                      .onError(showError);
                },
                child: Text(toBeginningOfSentenceCase(action.name)),
              ),
            ],
          );
        },
      ),
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
                            Chip(
                              label: Text(pronoun.summary),
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                              color: WidgetStatePropertyAll(
                                theme.colorScheme.primary,
                              ),
                            ),
                          if (profile.timezone != null)
                            Chip(
                              label: Text(profile.timezone!),
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                              color: WidgetStatePropertyAll(
                                theme.colorScheme.primary,
                              ),
                            ),
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

              if (ref.watch(
                        PowerLevelController.provider(
                          PowerLevelConfig(
                            eventType: "m.room.member",
                            action: MembershipAction.kick,
                            isStateEvent: true,
                            targetUser: member.userId,
                          ),
                        ),
                      ) &&
                      member.status == MembershipStatus.join ||
                  member.status == MembershipStatus.invite)
                FilledButton.icon(
                  onPressed: () => showMembershipDialog(MembershipAction.kick),
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
              if (ref.watch(
                PowerLevelController.provider(
                  PowerLevelConfig(
                    eventType: "m.room.member",
                    action: MembershipAction.ban,
                    isStateEvent: true,
                    targetUser: member.userId,
                  ),
                ),
              ))
                ElevatedButton.icon(
                  onPressed: () => showMembershipDialog(
                    member.status == MembershipStatus.ban
                        ? MembershipAction.unban
                        : MembershipAction.ban,
                  ),
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
