import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/room_profile.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/main.dart";
import "package:nexus/models/profile_response.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/avatars/editable_avatar.dart";
import "package:nexus/widgets/settings/inline_text_field.dart";

/// Edits the avatar and display name the current user has in [roomId].
class const RoomProfileSheet(final String roomId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(ClientStateController.provider)?.userId ?? "";
    final controller = ref.read(
      RoomProfileController.provider(roomId).notifier,
    );
    Future<void> setField(String field, Object? value) =>
        controller.setFields(.new({field: value})).onError(showError);

    return SheetLayout(
      title: Text("Room Profile"),
      actions: [
        TextButton(
          onPressed: () => controller.reset().onError(showError),
          child: Text("Use Global Profile"),
        ),
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Done")),
      ],
      children: [
        Text(
          "Your avatar and display name in this room only. Changing your global profile may replace them.",
        ),
        ref
            .watch(RoomProfileController.provider(roomId))
            .betterWhen(
              skipLoadingOnReload: true,
              data: (member) {
                final name = member?.displayName ?? userId.localpart ?? userId;

                return Column(
                  spacing: 8,
                  children: [
                    EditableAvatar(
                      hasAvatar: member?.avatarUrl != null,
                      onChanged: (url) =>
                          setField(Profile.avatarUrlKey, url?.toString()),
                      child: AvatarOrHash(
                        member?.avatarUrl,
                        name,
                        dimension: 200,
                      ),
                    ),
                    InlineTextField(
                      value: member?.displayName,
                      hint: userId.localpart ?? userId,
                      style: Theme.of(context).textTheme.headlineLarge,
                      onChanged: member == null
                          ? null
                          : (value) => setField(
                              Profile.displayNameKey,
                              value.isEmpty ? null : value,
                            ),
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}
