import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/sheet_layout.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/profile.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/create_room.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_action.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/start_dm_sheet.dart";

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
    final subtitleStyle = textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final client = ref.read(ClientController.provider.notifier);

    void showMembershipSheet(MembershipAction action) =>
        context.showAdaptiveSheet(
          (context) => HookBuilder(
            builder: (context) {
              final actionReasonController = useTextEditingController();
              return SheetLayout(
                title: Text(
                  "${toBeginningOfSentenceCase(action.name)} $userId",
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
                children: [
                  Text("Are you sure you want to ${action.name} $userId?"),
                  TextField(
                    textCapitalization: .sentences,
                    controller: actionReasonController,
                    decoration: .new(
                      labelText: "Reason for ${action.name} (optional)",
                    ),
                  ),
                ],
              );
            },
          ),
        );

    return SingleChildScrollView(
      child: Padding(
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
                dimension: 200,
              ),
            ),

            SizedBox(height: 8),

            SelectableText(
              member.displayName ?? userId.localpart,
              style: textTheme.headlineLarge,
              textAlign: .center,
            ),
            SelectableText(userId, textAlign: .center, style: subtitleStyle),

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
                                    style: subtitleStyle,
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
                              style: subtitleStyle,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

            SizedBox(height: 8),
            if (userId !=
                ref.watch(ClientStateController.provider)?.userId) ...[
              Row(
                children: [
                  Expanded(
                    child: M3EButton.icon(
                      onPressed: () async {
                        final name = member.displayName ?? userId.localpart;
                        final hasDm = ref
                            .read(RoomsController.provider)
                            .values
                            .any((room) => room.metadata?.dmUserId == userId);

                        if (hasDm) {
                          context.startDirectMessage(userId, name: name);
                        } else if (await context.showAdaptiveSheet<bool>(
                              (_) => StartDmSheet(userId: userId, name: name),
                            ) !=
                            true) {
                          return;
                        }

                        if (context.mounted) Navigator.of(context).pop();
                      },
                      shape: .square,
                      style: .tonal,
                      icon: Icon(Icons.message),
                      label: Text("Message"),
                    ),
                  ),
                ],
              ),

              if (roomId != null &&
                  ref.watch(
                    PowerLevelController.provider(
                      .membershipAction(
                        action: .kick,
                        roomId: roomId!,
                        targetUser: userId,
                      ),
                    ),
                  ))
                Padding(
                  padding: .only(top: 4),
                  child: Row(
                    spacing: 8,
                    children: [
                      if (member.status == .join || member.status == .invite)
                        M3EButton.icon(
                          onPressed: () => showMembershipSheet(.kick),
                          shape: .square,
                          icon: Icon(Icons.sports_martial_arts),
                          label: Text("Kick"),
                          decoration: .styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          ),
                        ),

                      M3EButton.icon(
                        onPressed: () => showMembershipSheet(.ban),
                        shape: .square,
                        icon: Icon(Icons.gavel),
                        label: Text("Ban"),
                        decoration: .styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ].map((e) => Expanded(child: e)).toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
