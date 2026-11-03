import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/bot_command.dart";

class GomuksCommandsController extends AsyncNotifier<IList<BotCommand>> {
  static const unsupported = ISetConst({
    // Needs gomuks web
    "devtools",
    "upgraderoom",

    // Needs attachment stuff
    "myroomavatar",
    "globalavatar",
    "roomavatar",

    // Already in Nexus' UI with a better UX
    "poll",
  });

  @override
  Future<IList<BotCommand>> build() async =>
      (await ref
              .read(ClientController.provider.notifier)
              .getCommandDefinitions())
          .where(
            (description) =>
                description.isValid &&
                !unsupported.contains(description.command),
          )
          .map(
            (description) => BotCommand(
              sender: BotCommand.gomuksSender,
              botName: "gomuks",
              description: description,
            ),
          )
          .toIList();

  static final provider =
      AsyncNotifierProvider<GomuksCommandsController, IList<BotCommand>>(
        GomuksCommandsController.new,
      );
}
