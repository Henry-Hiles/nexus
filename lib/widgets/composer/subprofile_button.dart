import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/subprofiles.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/main.dart";
import "package:nexus/models/room_subprofiles.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";

/// Chooses the subprofile messages are sent as in [roomId], if subprofiles are
/// on. It shows the one the text in [controller] would trigger, if any.
class const SubprofileButton(
  final String roomId, {
  required final TextEditingController controller,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      SettingsController.provider.select(
        (settings) => settings.value?.subprofiles ?? false,
      ),
    );
    final subprofiles = ref.watch(SubprofilesController.provider(roomId));
    final RoomSubprofiles(:profiles, :current) = subprofiles;
    final triggered = useListenableSelector(
      controller,
      () => subprofiles.triggeredBy(controller.text),
    );
    if (!enabled || profiles.isEmpty) return const SizedBox.shrink();
    final shown = triggered ?? current;

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
      tooltip: switch ((triggered, current)) {
        (final triggered?, _) =>
          "Sending this message as ${triggered.displayName ?? triggered.id}",
        (null, final current?) =>
          "Sending as ${current.displayName ?? current.id}",
        (null, null) => "Choose subprofile",
      },
      icon: switch (shown) {
        final shown? => AvatarOrHash(
          shown.avatarUrl,
          shown.displayName ?? shown.id,
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
