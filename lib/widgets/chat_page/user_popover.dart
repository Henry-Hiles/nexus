import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/widgets/avatar_or_hash.dart";

class UserPopover extends ConsumerWidget {
  final Membership member;
  const UserPopover(this.member, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            AvatarOrHash(member.avatarUrl, member.displayName, height: 80),
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
        if (member.userId != ref.watch(ClientStateController.provider)?.userId)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: null, label: Text("Message")),
              FilledButton.icon(
                onPressed: null,
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
                onPressed: null,
                label: Text("Ban"),
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
