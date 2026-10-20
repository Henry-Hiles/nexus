import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_leave_room_sheet.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/sheet_layout.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/widgets/adaptive_menu_button.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/models/room.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:nexus/main.dart";

final class const RoomMenuButton(
  final Room? room, {
  final IList<Room> children = const .empty(),
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danger = Theme.of(context).colorScheme.error;
    final client = ref.read(ClientController.provider.notifier);

    return AdaptiveMenuButton(
      icon: const Icon(Icons.more_vert),
      tooltip: "Room options",
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
              final vias = ref.read(ViaController.provider(room!));

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
            onTap: () => context.showAdaptiveSheet(
              (context) => HookBuilder(
                builder: (context) {
                  final userIdController = useTextEditingController();
                  final reasonController = useTextEditingController();
                  final text = useValueListenable(userIdController).text.trim();
                  final valid = text.isValidUserId;

                  void submit() {
                    if (!valid) return;
                    Navigator.of(context).pop();
                    final reason = reasonController.text.trim();
                    client
                        .setMembership(
                          .new(
                            userId: text,
                            roomId: room!.metadata!.id,
                            action: .invite,
                            reason: reason.isEmpty ? null : reason,
                          ),
                        )
                        .onError(showError);
                  }

                  return SheetLayout(
                    title: Text("Invite User"),
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
                    children: [
                      TextField(
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
                      TextField(
                        controller: reasonController,
                        textCapitalization: .sentences,
                        onSubmitted: (_) => submit(),
                        decoration: const .new(
                          labelText: "Invite reason (optional)",
                        ),
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
            onTap: () => context.showLeaveRoomSheet(
              room!.metadata!.id,
              name: room!.metadata?.name ?? "Unnamed Room",
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
