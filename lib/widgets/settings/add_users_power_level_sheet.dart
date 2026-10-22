import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/members.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/settings/power_level_field.dart";
import "package:nexus/widgets/settings/search_chooser.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Chooses users of [roomId] to give a power level of their own.
class const AddUsersPowerLevelSheet({
  required final String roomId,

  /// Users who already have a level, or can't be given one, so aren't suggested.
  required final ISet<String> existing,

  /// The user's own power level, which they can't set levels above.
  required final double ownLevel,
  required final void Function(ISet<String> users, int level) onSave,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = useState(const ISet<String>.empty());
    final error = useState<String?>(null);
    final searchController = useTextEditingController();
    final levelController = useTextEditingController(text: "0");
    final level = PowerLevelField.levelFrom(
      useValueListenable(levelController).text,
      ownLevel,
    );

    final members = IMap.fromEntries(
      (ref.watch(MembersController.provider(roomId)).value ??
              const ISet.empty())
          .map(
            (event) => switch ((event.stateKey, event.content)) {
              (final userId?, final MembershipContent content)
                  when content.status == .join || content.status == .invite =>
                MapEntry(userId, content),
              _ => null,
            },
          )
          .nonNulls,
    );

    String nameOf(String id) => members[id]?.displayName ?? id.localpart;

    void add(String id) {
      if (existing.contains(id)) {
        error.value = "Already has a power level";
        return;
      }
      chosen.value = chosen.value.add(id);
      searchController.clear();
    }

    final valid = chosen.value.isNotEmpty && level != null;
    void save() {
      Navigator.of(context).pop();
      onSave(chosen.value, level!);
    }

    return SheetLayout(
      title: Text("Add Users"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: valid ? save : null, child: Text("Save")),
      ],
      children: [
        SearchChooser(
          controller: searchController,
          chosen: chosen.value,
          options: members.keys
              .where((id) => !existing.contains(id))
              .sortedBy((id) => nameOf(id).toLowerCase())
              .toIList(),
          nameOf: nameOf,
          avatarOf: (id) =>
              AvatarOrHash(members[id]?.avatarUrl, nameOf(id), dimension: 40),
          subtitleOf: (id) => id,
          onAdded: add,
          onRemoved: (id) => chosen.value = chosen.value.remove(id),
          onSubmitted: (text, topMatch) {
            if (RegExp(r"^@[^:]+:.+$").hasMatch(text)) {
              add(text);
            } else if (topMatch != null) {
              add(topMatch);
            } else {
              error.value = "Enter a user ID";
            }
          },
          onChanged: (_) => error.value = null,
          label: "Add user",
          hint: "Search members, or enter a user ID",
          removeTooltip: "Remove user",
          error: error.value,
          autofocus: true,
        ),
        PowerLevelField(
          controller: levelController,
          ownLevel: ownLevel,
          onSubmitted: valid ? save : null,
        ),
      ],
    );
  }
}
