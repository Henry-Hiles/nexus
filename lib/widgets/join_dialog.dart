import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/widgets/room_summary_dialog.dart";

class const JoinDialog(final WidgetRef ref, {super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final roomAlias = useTextEditingController();

    Future<void> onJoin() async {
      Navigator.of(context).pop();

      final linkInfo = roomAlias.text.linkInfo;
      final roomIdOrAlias = linkInfo?.identifier ?? roomAlias.text;

      showDialog(
        context: context,
        builder: (context) => Consumer(
          builder: (context, ref, _) => switch (ref.watch(
            RoomSummaryController.provider(
              .new(
                roomIdOrAlias: roomIdOrAlias,
                via: linkInfo?.via ?? const IList.empty(),
              ),
            ),
          )) {
            AsyncData(:final value) => RoomSummaryDialog(
              value,
              via: linkInfo?.via,
            ),
            AsyncError _ || AsyncLoading _ => RoomSummaryDialog(
              .new(roomId: roomIdOrAlias),
              via: linkInfo?.via,
            ),
          },
        ),
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
