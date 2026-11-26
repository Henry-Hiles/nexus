import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/subprofiles.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";

/// Chooses the subprofile messages are sent as in [roomId], if subprofiles are on.
class const SubprofileButton(final String roomId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      SettingsController.provider.select(
        (settings) => settings.value?.subprofiles ?? false,
      ),
    );
    final (:profiles, :current) = ref.watch(
      SubprofilesController.provider(roomId),
    );
    if (!enabled || profiles.isEmpty) return const SizedBox.shrink();

    Future<void> choose(String profileId) => ref
        .read(AccountDataController.provider.notifier)
        .setRoomProfile(roomId, profileId)
        .onError(showError);

    PopupMenuItem<void> item({
      required String id,
      required Widget leading,
      required String title,
    }) {
      final selected = (current?.id ?? "") == id;
      return PopupMenuItem(
        onTap: () => choose(id),
        child: ListTile(
          selected: selected,
          leading: leading,
          title: Text(title),
          trailing: selected ? Icon(Icons.check) : null,
        ),
      );
    }

    return AdaptiveMenuButton<void>(
      tooltip: switch (current) {
        final current? => "Sending as ${current.displayName ?? current.id}",
        null => "Choose subprofile",
      },
      icon: switch (current) {
        final current? => AvatarOrHash(
          current.avatarUrl,
          current.displayName ?? current.id,
        ),
        null => Icon(Icons.person),
      },
      itemBuilder: (_) => [
        item(id: "", leading: Icon(Icons.person), title: "Account Profile"),
        ...profiles.map(
          (profile) => item(
            id: profile.id,
            leading: AvatarOrHash(
              profile.avatarUrl,
              profile.displayName ?? profile.id,
            ),
            title: profile.displayName ?? profile.id,
          ),
        ),
      ],
    );
  }
}
