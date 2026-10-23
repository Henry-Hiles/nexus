import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/sheet_layout.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/mutual_rooms.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/profile.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/create_room.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/mutual_rooms_sheet.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_action.dart";
import "package:nexus/models/profile_response.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/editable_avatar.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/settings/inline_text_field.dart";
import "package:nexus/widgets/start_dm_sheet.dart";
import "package:nexus/widgets/timezone_field.dart";

final class const UserBottomSheet(
  final String userId, {
  final String? roomId,

  /// Edits the current user's global profile, instead of showing actions.
  final bool editable = false,
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
    final profileController = ref.read(
      ProfileController.provider(userId).notifier,
    );
    Future<void> setProfileField(String field, Object? value) =>
        profileController.setField(field, value).onError(showError);

    final profile = ref
        .watch(ProfileController.provider(userId))
        .value
        ?.profile;
    final englishPronouns = (profile?.pronouns ?? const IList<Pronoun>.empty())
        // TODO: Check system language (l10n)
        .where((pronoun) => pronoun.language == "en");
    final divider = SizedBox(
      height: 16,
      child: VerticalDivider(
        thickness: 1.5,
        width: 4,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    Widget avatarOf(MembershipContent member) => ExpandableImage(
      member.avatarUrl == null ? null : .new(mxc: member.avatarUrl!),
      downloadFilename: member.displayName ?? userId.localpart,
      child: AvatarOrHash(
        member.avatarUrl,
        member.displayName ?? userId.localpart,
        dimension: 200,
      ),
    );

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

    return switch (ref.watch(
      UserController.provider(.new(roomId: roomId, userId: userId)),
    )) {
      AsyncError(:final error, :final stackTrace) => ErrorDialog(
        error,
        stackTrace,
      ),
      AsyncData(value: final member) ||
      AsyncLoading(value: final member?) => SingleChildScrollView(
        child: Padding(
          padding: .all(editable ? 16 : 42),
          child: Column(
            spacing: 4,
            mainAxisSize: .min,
            crossAxisAlignment: .center,
            children: [
              if (!editable) ...[
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
              ],

              if (editable)
                EditableAvatar(
                  hasAvatar: member.avatarUrl != null,
                  onChanged: (url) => setProfileField(
                    Profile.avatarUrlKey,
                    url?.toString() ?? "",
                  ),
                  child: avatarOf(member),
                )
              else
                avatarOf(member),

              SizedBox(height: 8),

              if (editable)
                InlineTextField(
                  value: profile?.displayName,
                  hint: userId.localpart,
                  style: textTheme.headlineLarge,
                  onChanged: profile == null
                      ? null
                      : (value) =>
                            setProfileField(Profile.displayNameKey, value),
                )
              else
                SelectableText(
                  member.displayName ?? userId.localpart,
                  style: textTheme.headlineLarge,
                  textAlign: .center,
                ),
              SelectableText(userId, textAlign: .center, style: subtitleStyle),

              ref
                  .watch(ProfileController.provider(userId))
                  .betterWhen(
                    // Keeps showing the profile while it's fetched again after saving
                    skipLoadingOnRefresh: true,
                    loading: () => Text(""),
                    data: (profileResponse) => Column(
                      children: [
                        Wrap(
                          crossAxisAlignment: .center,
                          alignment: .center,
                          spacing: 4,
                          runSpacing: 4,
                          children: editable
                              ? [
                                  InlineTextField(
                                    value: englishPronouns
                                        .map((pronoun) => pronoun.summary)
                                        .join(", "),
                                    hint: "Pronouns, e.g. they/them",
                                    balanced: false,
                                    style: subtitleStyle,
                                    onChanged: (value) {
                                      final pronouns = profileResponse
                                          .profile
                                          .pronouns
                                          .where(
                                            (pronoun) =>
                                                // TODO: Check system language (l10n)
                                                pronoun.language != "en",
                                          )
                                          .toIList()
                                          .addAll(
                                            value
                                                .split(",")
                                                .map(
                                                  (summary) => summary.trim(),
                                                )
                                                .where(
                                                  (summary) =>
                                                      summary.isNotEmpty,
                                                )
                                                .map(
                                                  (summary) => Pronoun(
                                                    language: "en",
                                                    summary: summary,
                                                  ),
                                                ),
                                          );

                                      return setProfileField(
                                        Profile.unstablePronounsKey,
                                        pronouns.isEmpty
                                            ? null
                                            : pronouns
                                                  .map(
                                                    (pronoun) =>
                                                        pronoun.toJson(),
                                                  )
                                                  .toList(),
                                      );
                                    },
                                  ),
                                  divider,
                                  TimezoneField(
                                    value: profileResponse.profile.timezone,
                                    style: subtitleStyle,
                                    onChanged: (value) => setProfileField(
                                      Profile.timezoneKey,
                                      value,
                                    ),
                                  ),
                                ]
                              : [
                                  ...englishPronouns
                                      .mapIndexed(
                                        (index, pronoun) => [
                                          if (index != 0)
                                            Icon(
                                              Icons.circle,
                                              size: 4,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          Text(
                                            pronoun.summary,
                                            textAlign: .center,
                                            style: subtitleStyle,
                                          ),
                                        ],
                                      )
                                      .flattened,

                                  if (profileResponse.profile.timezone !=
                                      null) ...[
                                    if (profileResponse
                                        .profile
                                        .pronouns
                                        .isNotEmpty)
                                      divider,
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

              if (!editable &&
                  userId != ref.watch(ClientStateController.provider)?.userId)
                switch (ref.watch(MutualRoomsController.provider(userId))) {
                  AsyncData(value: final roomIds) => switch (ref.watch(
                    RoomsController.provider.select(
                      (rooms) => roomIds.where(rooms.containsKey).length,
                    ),
                  )) {
                    0 => SizedBox.shrink(),
                    final count => TextButton(
                      onPressed: () => context.showAdaptiveSheet(
                        (_) => MutualRoomsSheet(userId),
                      ),
                      child: Text(
                        "$count mutual ${Intl.plural(count, one: "room", other: "rooms")}",
                      ),
                    ),
                  },
                  _ => SizedBox.shrink(),
                },

              SizedBox(height: 8),
              if (editable ||
                  userId !=
                      ref.watch(ClientStateController.provider)?.userId) ...[
                Row(
                  children: [
                    Expanded(
                      child: M3EButton.icon(
                        onPressed: editable
                            ? null
                            : () async {
                                final name =
                                    member.displayName ?? userId.localpart;
                                final hasDm = ref
                                    .read(RoomsController.provider)
                                    .values
                                    .any(
                                      (room) =>
                                          room.metadata?.dmUserId == userId,
                                    );

                                if (hasDm) {
                                  context.startDirectMessage(
                                    userId,
                                    name: name,
                                  );
                                } else if (await context
                                        .showAdaptiveSheet<bool>(
                                          (_) => StartDmSheet(
                                            userId: userId,
                                            name: name,
                                          ),
                                        ) !=
                                    true) {
                                  return;
                                }

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
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
                    member.status == .knock &&
                    ref.watch(
                      PowerLevelController.provider(
                        .membershipAction(
                          action: .invite,
                          roomId: roomId!,
                          targetUser: userId,
                        ),
                      ),
                    ))
                  Padding(
                    padding: .only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: M3EButton.icon(
                            onPressed: () => client
                                .setMembership(
                                  .new(
                                    userId: userId,
                                    roomId: roomId!,
                                    action: .invite,
                                  ),
                                )
                                .onError(showError),
                            shape: .square,
                            icon: Icon(Icons.check),
                            label: Text("Accept knock"),
                            decoration: .styleFrom(
                              backgroundColor: theme.successScheme.primary,
                              foregroundColor: theme.successScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Shown as a moderator would see it, while editing
                if (editable ||
                    (roomId != null &&
                        ref.watch(
                          PowerLevelController.provider(
                            .membershipAction(
                              action: .kick,
                              roomId: roomId!,
                              targetUser: userId,
                            ),
                          ),
                        )))
                  Padding(
                    padding: .only(top: 4),
                    child: Row(
                      spacing: 8,
                      children: [
                        if (editable ||
                            switch (member.status) {
                              .join || .invite || .knock => true,
                              _ => false,
                            })
                          M3EButton.icon(
                            onPressed: editable
                                ? null
                                : () => showMembershipSheet(.kick),
                            shape: .square,
                            icon: Icon(Icons.sports_martial_arts),
                            label: Text("Kick"),
                            decoration: .styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                          ),

                        M3EButton.icon(
                          onPressed: editable
                              ? null
                              : () => showMembershipSheet(.ban),
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
      ),
      AsyncLoading _ => Loading(),
    };
  }
}
