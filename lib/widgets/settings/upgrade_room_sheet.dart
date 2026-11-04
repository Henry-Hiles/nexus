import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/capabilities.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/room_version_at_least.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:nexus/widgets/settings/member_chooser.dart";

/// Chooses a room version to upgrade [roomId] to, and its additional creators if the version has them.
class const UpgradeRoomSheet({
  required final String roomId,
  required final String currentVersion,

  /// The room's current creators, other than the user, to keep in the new room.
  required final ISet<String> creators,
  required final String? userId,
  required final void Function(String version, ISet<String> creators) onSave,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomVersions = ref
        .watch(CapabilitiesController.provider)
        .whenData((capabilities) => capabilities.roomVersions);
    final chosen = useState<String?>(null);
    final chosenCreators = useState(creators);

    final versions = roomVersions.value;
    final version = chosen.value ?? versions?.defaultVersion;

    final valid = version != null;
    final withCreators = valid && version.versionAtLeast(12);
    void save() {
      Navigator.of(context).pop();
      onSave(version!, withCreators ? chosenCreators.value : const .empty());
    }

    return SheetLayout(
      title: Text("Upgrade Room"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: valid ? save : null, child: Text("Upgrade")),
      ],
      children: [
        Text(
          "Upgrading creates a new room with the chosen version and closes this one, pointing its members to the new room. Members will have to join the new room themselves.",
        ),
        roomVersions.betterWhen(
          data: (versions) => versions == null
              ? Text(
                  "Your homeserver didn't list the room versions it supports.",
                )
              : DialogListTile<String>(
                  icon: Icon(Icons.upgrade),
                  title: "Room Version",
                  subtitle: Text("The version the new room will have."),
                  value: version,
                  options: versions.available.keys.sortedBy(
                    (option) => int.tryParse(option) ?? double.infinity,
                  ),
                  getName: (option) => switch ([
                    if (option == currentVersion) "current",
                    if (option == versions.defaultVersion) "default",
                    if (versions.available[option] == .unstable) "unstable",
                  ]) {
                    final labels when labels.isNotEmpty =>
                      "$option (${labels.join(", ")})",
                    _ => option,
                  },
                  onChanged: (value) => chosen.value = value,
                ),
        ),
        AnimatedSize(
          duration: Durations.medium2,
          curve: Curves.easeInOut,
          alignment: .topCenter,
          child: withCreators
              ? MemberChooser(
                  roomId: roomId,
                  chosen: chosenCreators.value,
                  excluded: ISet([?userId]),
                  excludedError: "You'll be a creator already",
                  onAdded: (id) =>
                      chosenCreators.value = chosenCreators.value.add(id),
                  onRemoved: (id) =>
                      chosenCreators.value = chosenCreators.value.remove(id),
                  label: "Add creator",
                  removeTooltip: "Remove creator",
                  emptyText: "Creators outrank everyone in the new room, and can't be demoted. You'll be one, and can add others.",
                )
              : const SizedBox(width: .infinity),
        ),
      ],
    );
  }
}
