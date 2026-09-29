import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/widgets/room_summary_dialog.dart";

class const JoinDialog(final WidgetRef ref, {super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final roomAlias = useTextEditingController();

    Future<void> onJoin() async {
      Navigator.of(context).pop();

      final roomIdOrAlias = roomAlias.text.mention ?? roomAlias.text;
      final via = roomAlias.text.via;

      showDialog(
        context: context,
        builder: (context) => switch (ref.watch(
          RoomSummaryController.provider(
            .new(roomIdOrAlias: roomIdOrAlias, via: via),
          ),
        )) {
          AsyncData(:final value) => RoomSummaryDialog(value, via: via),
          AsyncError _ || AsyncLoading _ => RoomSummaryDialog(
            .new(roomId: roomAlias.text),
            via: via,
          ),
        },
      );
    }

    return AlertDialog(
      title: Text("Join a Room"),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text("Enter the room alias, Matrix URI, or Matrix.to link."),
          SizedBox(height: 12),
          TextField(
            controller: roomAlias,
            decoration: .new(hintText: "#room:server.name"),
            onEditingComplete: onJoin,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: onJoin, child: Text("Join")),
      ],
    );
  }
}
