import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extensions/join_room_with_snackbars.dart";
import "package:nexus/widgets/form_text_input.dart";

class JoinDialog extends HookConsumerWidget {
  const JoinDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAlias = useTextEditingController();
    return AlertDialog(
      title: Text("Join a Room"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Enter the room alias, ID, or a Matrix.to link."),
          SizedBox(height: 12),
          FormTextInput(
            required: false,
            capitalize: true,
            controller: roomAlias,
            title: "#room:server",
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();

            final client = ref.watch(ClientController.provider.notifier);
            if (context.mounted) {
              client.joinRoomWithSnackBars(context, roomAlias.text, ref);
            }
          },
          child: Text("Join"),
        ),
      ],
    );
  }
}
