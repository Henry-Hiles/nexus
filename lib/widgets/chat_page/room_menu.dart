import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:matrix/matrix.dart";
import "package:nexus/helpers/extensions/room_to_children.dart";
import "package:nexus/widgets/form_text_input.dart";

class RoomMenu extends StatelessWidget {
  final Room room;
  const RoomMenu(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;

    void markRead(String roomId) async {
      for (final child in await room.getAllChildren()) {
        await child.roomData.setReadMarker(
          child.roomData.lastEvent?.eventId,
          mRead: child.roomData.lastEvent?.eventId,
        );
      }
    }

    return PopupMenuButton(
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () async {
            final link = await room.matrixToInviteLink();
            await Clipboard.setData(ClipboardData(text: link.toString()));
          },
          child: ListTile(leading: Icon(Icons.link), title: Text("Copy Link")),
        ),
        PopupMenuItem(
          onTap: () => markRead(room.id),
          child: ListTile(
            leading: Icon(Icons.check),
            title: Text("Mark as Read"),
          ),
        ),
        PopupMenuItem(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Leave Room"),
              content: Text(
                "Are you sure you want to leave \"${room.getLocalizedDisplayname()}\"?",
              ),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final snackbar = ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Leaving room...")));
                    await room.leave();
                    snackbar.close();
                  },
                  child: Text("Leave"),
                ),
              ],
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.logout, color: danger),
            title: Text("Leave", style: TextStyle(color: danger)),
          ),
        ),
        PopupMenuItem(
          onTap: () => showDialog(
            context: context,
            builder: (context) => HookBuilder(
              builder: (_) {
                final reasonController = useTextEditingController();
                return AlertDialog(
                  title: Text("Report"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Report this room to your server administrators, who can take action like banning this room.",
                      ),

                      SizedBox(height: 12),
                      FormTextInput(
                        required: false,
                        capitalize: true,
                        controller: reasonController,
                        title: "Reason for report (optional)",
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        room.client.reportRoom(room.id, reasonController.text);
                        Navigator.of(context).pop();
                      },
                      child: Text("Report"),
                    ),
                  ],
                );
              },
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.report, color: danger),
            title: Text("Report", style: TextStyle(color: danger)),
          ),
        ),
      ],
    );
  }
}
