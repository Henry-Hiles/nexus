import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/displayname_color.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/power_level_permission.dart";

/// Whose power levels, and which permissions' levels, a power levels event
/// changed, in green when raised, and red when lowered.
class const PowerLevelsDiff(
  final String roomId,
  final PowerLevelsContent content, {
  final PowerLevelsContent? previous,
  super.key,
}) extends ConsumerWidget {
  static const maxShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    final before = previous ?? PowerLevelsContent();

    Text levels(int? from, int? to, {int? fromLevel, int? toLevel}) => Text(
      "${from ?? "Default"} → ${to ?? "Default"}",
      style: style?.copyWith(
        color: switch ((fromLevel ?? from, toLevel ?? to)) {
          (final from?, final to?) when to > from =>
            theme.successScheme.primary,
          (final from?, final to?) when to < from => theme.colorScheme.error,
          _ => theme.colorScheme.onSurfaceVariant,
        },
      ),
    );

    Iterable<Widget> capped(Iterable<Widget> lines) {
      final list = lines.toList();
      return [
        ...list.take(maxShown),
        if (list.length > maxShown)
          Text(
            "+${list.length - maxShown} more",
            style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ];
    }

    final users = before.users.keys
        .toISet()
        .addAll(content.users.keys)
        .map(
          (userId) => (
            userId,
            from: before.users[userId],
            to: content.users[userId],
            fromLevel: before.users[userId] ?? before.usersDefault,
            toLevel: content.users[userId] ?? content.usersDefault,
          ),
        )
        .where((change) => change.from != change.to)
        // The most powerful first
        .toIList()
        .sort((a, b) => b.toLevel.compareTo(a.toLevel));

    final permissions = <(String, int?, int?)>[
      ...PowerLevelPermission.values.map(
        (permission) => (
          permission.title,
          permission.levelIn(before),
          permission.levelIn(content),
        ),
      ),
      ...before.events.keys
          .toISet()
          .addAll(content.events.keys)
          .map(
            (type) => (
              PowerLevelEvent.of(type)?.title ?? type,
              before.events[type],
              content.events[type],
            ),
          ),
    ].where((permission) => permission.$2 != permission.$3);

    return Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        ...capped(
          users.map(
            (change) => Wrap(
              spacing: 8,
              crossAxisAlignment: .center,
              children: [
                Text(
                  ref
                          .watch(
                            UserController.provider(
                              .new(roomId: roomId, userId: change.$1),
                            ),
                          )
                          .value
                          ?.displayName ??
                      change.$1.localpart,
                  style: style?.copyWith(
                    fontWeight: .bold,
                    color: ref.displaynameColorAt(
                      change.$1,
                      change.toLevel.toDouble(),
                    ),
                  ),
                ),
                levels(
                  change.from,
                  change.to,
                  fromLevel: change.fromLevel,
                  toLevel: change.toLevel,
                ),
              ],
            ),
          ),
        ),
        ...capped(
          permissions.map(
            (permission) => Wrap(
              spacing: 8,
              crossAxisAlignment: .center,
              children: [
                Text(permission.$1, style: style?.copyWith(fontWeight: .bold)),
                levels(permission.$2, permission.$3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
