import "package:clipboard/clipboard.dart";
import "package:flutter/material.dart";
import "package:matrix/matrix.dart";

class RoomMenu extends StatelessWidget {
  final Room room;
  const RoomMenu(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;

    return PopupMenuButton(
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () async {
            final link = await room.matrixToInviteLink();
            await FlutterClipboard.copy(link.toString());
          },
          child: ListTile(leading: Icon(Icons.link), title: Text("Copy Link")),
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
      ],
    );
  }
}
