import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/models/room.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:nexus/main.dart";

final class const RoomMenuButton(
  final Room? room, {
  final IList<Room> children = const IList.empty(),
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danger = Theme.of(context).colorScheme.error;
    final client = ref.read(ClientController.provider.notifier);

    return PopupMenuButton(
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () async {
            if (room != null) await client.markRead(room!);
            await Future.wait(children.map((child) => client.markRead(child)));
          },
          child: ListTile(
            leading: Icon(Icons.check),
            title: Text("Mark as Read"),
          ),
        ),
        if (room != null) ...[
          PopupMenuItem(
            onTap: () async {
              final vias = ref.watch(ViaController.provider(room!));

              await Clipboard.setData(
                .new(
                  text: "matrix:roomid/${room!.metadata?.id.substring(1)}$vias",
                ),
              );
            },
            child: ListTile(
              leading: Icon(Icons.link),
              title: Text("Copy Link"),
            ),
          ),
          PopupMenuItem(
            onTap: () => showDialog(
              context: context,
              builder: (context) => HookBuilder(
                builder: (context) {
                  final userIdController = useTextEditingController();
                  final text = useValueListenable(userIdController).text.trim();
                  final valid = RegExp(r"^@[^:\s]+:[^\s]+$").hasMatch(text);

                  void submit() {
                    if (!valid) return;
                    Navigator.of(context).pop();
                    client
                        .setMembership(
                          .new(
                            userId: text,
                            roomId: room!.metadata!.id,
                            action: .invite,
                          ),
                        )
                        .onError(showError);
                  }

                  return AlertDialog(
                    title: Text("Invite User"),
                    content: TextField(
                      controller: userIdController,
                      autofocus: true,
                      keyboardType: .emailAddress,
                      onSubmitted: (_) => submit(),
                      decoration: .new(
                        labelText: "User ID",
                        hintText: "@user:example.com",
                        errorText: text.isEmpty || valid
                            ? null
                            : "Enter a valid user ID",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: Navigator.of(context).pop,
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: valid ? submit : null,
                        child: Text("Invite"),
                      ),
                    ],
                  );
                },
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.person_add),
              title: Text("Invite"),
            ),
          ),
          PopupMenuItem(
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Leave Room"),
                content: Text(
                  "Are you sure you want to leave \"${room!.metadata?.name ?? "Unnamed Room"}\"?",
                ),
                actions: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final snackbar = ScaffoldMessenger.of(context)
                          .showSnackBar(
                            .new(
                              content: Text("Leaving room..."),
                              duration: Duration(days: 1),
                            ),
                          );
                      await client.leaveRoom(room!);
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
      ],
    );
  }
}
