import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/helpers/file_dialog_helper.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/settings/text_setting_tile.dart";

class RoomSettingsSectionsController(final String roomId)
    extends AsyncNotifier<IMap<String, IList<SettingsCategory>>> {
  @override
  Future<IMap<String, IList<SettingsCategory>>> build() async {
    final room = ref.watch(
      RoomsController.provider.select((rooms) => rooms[roomId]),
    );
    final client = ref.read(ClientController.provider.notifier);

    // The room's own state, rather than metadata like a name made up from
    // its members when it has none
    Content? stateContent(EventType type) =>
        switch (room?.state[type.type]?[""]) {
          final rowId? => room?.events[rowId]?.content,
          null => null,
        };
    final name = switch (stateContent(.name)) {
      NameContent(:final name) => name,
      _ => null,
    };
    final topic = switch (stateContent(.topic)) {
      TopicContent(:final topic) => topic,
      _ => room?.metadata?.topic,
    };
    final avatar = switch (stateContent(.avatar)) {
      AvatarContent(:final url) => url,
      _ => room?.metadata?.avatar,
    };

    bool canSet(EventType type) => ref.watch(
      PowerLevelController.provider(.state(eventType: type, roomId: roomId)),
    );

    final canSetAvatar = canSet(.avatar);
    final canSetName = canSet(.name);
    final canSetTopic = canSet(.topic);

    Future<void> setState(EventType type, Content content) => client.setState(
      .new(roomId: roomId, type: type.type, stateKey: "", content: content),
    );

    return .new({
      "Room": .new([
        .new(
          title: "General",
          icon: Icons.tune,
          settings: .new([
            .new(
              title: "Avatar",
              description: "The image shown for the room.",
              icon: Icons.image,
              builder: (title, description, icon) => Builder(
                builder: (context) => ListTile(
                  enabled: canSetAvatar,
                  leading: Icon(icon),
                  title: Text(title),
                  subtitle: Text(description),
                  trailing: Row(
                    mainAxisSize: .min,
                    spacing: 8,
                    children: [
                      AvatarOrHash(
                        avatar,
                        name ?? "Unnamed Room",
                        dimension: 40,
                        fallback: Icon(Icons.numbers),
                      ),
                      if (avatar != null && canSetAvatar)
                        IconButton(
                          tooltip: "Remove avatar",
                          icon: Icon(Icons.delete),
                          onPressed: () => setState(
                            .avatar,
                            const .new(),
                          ).onError(showError),
                        ),
                    ],
                  ),
                  onTap: () async {
                    final file = await ProviderScope.containerOf(context)
                        .read(FileDialogHelper.provider)
                        .pickFile(images: true);
                    if (file == null || !context.mounted) return;

                    await context.withProgressSnackbar(
                      "Changing room avatar...",
                      () async {
                        final content = await client.uploadMedia(
                          .new(path: file.path, encrypt: false),
                        );
                        if (content case ImageMessageContent(
                          :final url,
                          :final info,
                        )) {
                          await setState(
                            .avatar,
                            AvatarContent(url: url, info: info),
                          );
                        } else {
                          throw Exception("The file isn't an image");
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            .new(
              title: "Room Name",
              description: "The name shown for the room.",
              icon: Icons.title,
              builder: (title, description, icon) => TextSettingTile(
                icon: Icon(icon),
                title: title,
                description: description,
                value: name,
                onChanged: canSetName
                    ? (value) => setState(
                        .name,
                        NameContent(name: value),
                      ).onError(showError)
                    : null,
              ),
            ),
            .new(
              title: "Topic",
              description: "A short description of the room.",
              icon: Icons.info,
              builder: (title, description, icon) => TextSettingTile(
                icon: Icon(icon),
                title: title,
                description: description,
                value: topic,
                multiline: true,
                onChanged: canSetTopic
                    ? (value) => setState(
                        .topic,
                        TopicContent(
                          topic: value,
                          content: .new(
                            representations: .new([.new(body: value)]),
                          ),
                        ),
                      ).onError(showError)
                    : null,
              ),
            ),
          ]),
        ),
      ]),
    });
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<
        RoomSettingsSectionsController,
        IMap<String, IList<SettingsCategory>>,
        String
      >(RoomSettingsSectionsController.new);
}
