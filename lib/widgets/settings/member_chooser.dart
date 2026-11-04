import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/members.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/settings/search_chooser.dart";

/// The [chosen] users, above a field searching [roomId]'s members, or taking a user ID, to choose more.
class const MemberChooser({
  required final String roomId,
  required final ISet<String> chosen,
  required final void Function(String userId) onAdded,
  required final void Function(String userId) onRemoved,
  required final String label,
  required final String removeTooltip,

  /// Users who can't be chosen, so aren't suggested.
  final ISet<String> excluded = const .empty(),

  /// Shown when trying to choose one of the [excluded] users.
  final String excludedError = "Can't be chosen",
  final String? emptyText,
  final bool autofocus = false,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = useState<String?>(null);
    final searchController = useTextEditingController();

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
      if (excluded.contains(id)) {
        error.value = excludedError;
        return;
      }
      onAdded(id);
      searchController.clear();
    }

    return SearchChooser(
      controller: searchController,
      chosen: chosen,
      options: members.keys
          .where((id) => !excluded.contains(id))
          .sortedBy((id) => nameOf(id).toLowerCase())
          .toIList(),
      nameOf: nameOf,
      avatarOf: (id) =>
          AvatarOrHash(members[id]?.avatarUrl, nameOf(id), dimension: 40),
      subtitleOf: (id) => id,
      onAdded: add,
      onRemoved: onRemoved,
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
      label: label,
      hint: "Search members, or enter a user ID",
      removeTooltip: removeTooltip,
      emptyText: emptyText,
      error: error.value,
      autofocus: autofocus,
    );
  }
}
