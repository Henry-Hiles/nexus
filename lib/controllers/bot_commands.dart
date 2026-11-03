import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/gomuks_commands.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/content/bot_command_description.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";

class BotCommandsController(final String roomId)
    extends AsyncNotifier<IList<BotCommand>> {
  @override
  Future<IList<BotCommand>> build() async {
    final gomuksCommands = await ref.watch(
      GomuksCommandsController.provider.future,
    );

    final botCommands = ref.watch(
      RoomsController.provider.select((rooms) {
        final room = rooms[roomId];
        if (room == null) return const IList<BotCommand>.empty();

        Content? membership(String userId) =>
            switch (room.state[EventType.membership.type]?[userId]) {
              final rowId? => room.events[rowId]?.content,
              null => null,
            };

        return (room.state[EventType.botCommandDescription.type]?.values ??
                const [])
            .map(
              (rowId) => switch (room.events[rowId]) {
                Event(
                  redactedBy: null,
                  :final sender,
                  content: final BotCommandDescriptionContent description,
                )
                    when description.isValid &&
                        !BotCommand.builtIn.contains(
                          description.command.split(" ").first,
                        ) =>
                  switch (membership(sender)) {
                    MembershipContent(
                      status: .join,
                      :final displayName,
                      :final avatarUrl,
                    ) =>
                      BotCommand(
                        sender: sender,
                        botName: displayName ?? sender.localpart,
                        botAvatar: avatarUrl,
                        description: description,
                      ),
                    _ => null,
                  },
                _ => null,
              },
            )
            .nonNulls
            .toIList();
      }),
    );

    return gomuksCommands
        .addAll(botCommands)
        .sortedBy((command) => command.description.command)
        .toIList();
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<BotCommandsController, IList<BotCommand>, String>(
        BotCommandsController.new,
      );
}
