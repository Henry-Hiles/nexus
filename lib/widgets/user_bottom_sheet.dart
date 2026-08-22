import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/profile.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_action.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/expandable_image.dart";

final class const UserBottomSheet(
  final MembershipContent member,
  final String userId, {
  final String? roomId,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final client = ref.watch(ClientController.provider.notifier);

    void showMembershipDialog(MembershipAction action) => showDialog(
      context: context,
      builder: (context) => HookBuilder(
        builder: (context) {
          final actionReasonController = useTextEditingController();
          return AlertDialog(
            title: Text("${toBeginningOfSentenceCase(action.name)} $userId"),
            content: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text("Are you sure you want to ${action.name} $userId?"),
                SizedBox(height: 12),
                TextField(
                  textCapitalization: .sentences,
                  controller: actionReasonController,
                  decoration: .new(
                    labelText: "Reason for ${action.name} (optional)",
                  ),
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
                        .new(
                          userId: userId,
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

    return Padding(
      padding: .all(42),
      child: Column(
        spacing: 4,
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: [
          Row(
            mainAxisAlignment: .end,
            children: [
              M3EButton(
                onPressed: Navigator.of(context).pop,
                child: Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 18),

          ExpandableImage(
            member.avatarUrl == null ? null : .new(mxc: member.avatarUrl!),
            child: AvatarOrHash(
              member.avatarUrl,
              member.displayName ?? userId.localpart,
              height: 200,
            ),
          ),

          SizedBox(height: 8),

          SelectableText(
            member.displayName ?? userId.localpart,
            style: textTheme.headlineLarge,
            textAlign: .center,
          ),
          SelectableText(
            userId,
            textAlign: .center,
            style: textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          ref
              .watch(ProfileController.provider(userId))
              .betterWhen(
                loading: () => Text(""),
                data: (profileResponse) => Column(
                  children: [
                    if (profileResponse.profile.timezone == null &&
                        profileResponse.profile.pronouns.isEmpty)
                      Text(""),
                    Wrap(
                      crossAxisAlignment: .center,
                      alignment: .center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...profileResponse.profile.pronouns
                            .where(
                              // TODO: Check system language (l10n)
                              (pronoun) => pronoun.language == "en",
                            )
                            .mapIndexed(
                              (index, pronoun) => [
                                if (index != 0)
                                  Icon(
                                    Icons.circle,
                                    size: 4,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                Text(
                                  pronoun.summary,
                                  textAlign: .center,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                            .flattened,

                        if (profileResponse.profile.timezone != null) ...[
                          if (profileResponse.profile.pronouns.isNotEmpty)
                            SizedBox(
                              height: 16,
                              child: VerticalDivider(
                                thickness: 1.5,
                                width: 4,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            profileResponse.profile.timezone!,
                            textAlign: .center,
                            style: textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

          SizedBox(height: 8),
          if (userId != ref.watch(ClientStateController.provider)?.userId &&
              roomId != null) ...[
            Row(
              children: [
                Expanded(
                  child: M3EButton.icon(
                    onPressed: null,
                    shape: .square,
                    style: .tonal,
                    icon: Icon(Icons.message),
                    label: Text("Message"),
                  ),
                ),
              ],
            ),

            if (ref.watch(
                      PowerLevelController.provider(
                        .membershipAction(
                          action: .kick,
                          roomId: roomId!,
                          targetUser: userId,
                        ),
                      ),
                    ) &&
                    member.status == .join ||
                member.status == .invite)
              Padding(
                padding: .only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  spacing: 8,
                  children: [
                    M3EButton.icon(
                      onPressed: () => showMembershipDialog(.kick),
                      shape: .square,
                      icon: Icon(Icons.sports_martial_arts),
                      label: Text("Kick"),
                      decoration: .new(
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.error,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.onError,
                        ),
                      ),
                    ),

                    M3EButton.icon(
                      onPressed: () => showMembershipDialog(.ban),
                      shape: .square,
                      icon: Icon(Icons.gavel),
                      label: Text("Ban"),
                      decoration: .new(
                        backgroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.errorContainer,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ].map((e) => Expanded(child: e)).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
