import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/join_rule_name.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/widgets/renderers/change_line.dart";

/// The join rule a join rules event changed to, and for restricted rooms, the
/// rooms whose members it let join, or stopped letting join.
class const JoinRulesDiff(
  final JoinRulesContent content, {
  final JoinRulesContent? previous,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final removedColor = theme.colorScheme.error;
    final addedColor = theme.successScheme.primary;

    ISet<String> roomIdsOf(JoinRulesContent? content) =>
        (content?.allow ?? const ISet<AllowCondition>.empty())
            .map((condition) => condition.roomId)
            .nonNulls
            .toISet();
    final before = roomIdsOf(previous);
    final after = roomIdsOf(content);
    final removed = before.difference(after);
    final added = after.difference(before);

    // Rooms the user isn't in are shown by ID
    final names = ref.watch(
      RoomsController.provider.select(
        (rooms) => IMap.fromEntries(
          removed
              .addAll(added)
              .map(
                (roomId) =>
                    MapEntry(roomId, rooms[roomId]?.metadata?.name ?? roomId),
              ),
        ),
      ),
    );
    IList<String> named(ISet<String> roomIds) =>
        roomIds.map((roomId) => names[roomId] ?? roomId).toIList();

    return Column(
      crossAxisAlignment: .start,
      spacing: 2,
      children: [
        if (previous?.joinRule != content.joinRule)
          ChangeLine(
            removed: [?previous?.joinRule.displayName].lock,
            added: [content.joinRule.displayName].lock,
            removedColor: removedColor,
            addedColor: addedColor,
            quoted: false,
          ),
        if (removed.isNotEmpty || added.isNotEmpty)
          ChangeLine(
            label: "Members of",
            removed: named(removed),
            added: named(added),
            removedColor: removedColor,
            addedColor: addedColor,
          ),
      ],
    );
  }
}
