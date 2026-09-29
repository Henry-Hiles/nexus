import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/room_summary.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/widgets/room_summary_dialog.dart";
import "package:nexus/main.dart";

class const JoinDialog(final WidgetRef ref, {super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final roomAlias = useTextEditingController();

    Future<void> onJoin() async {
      Navigator.of(context).pop();

      final roomIdOrAlias = roomAlias.text.mention ?? roomAlias.text;
      final IList<String> via = .new(
        Uri.tryParse(roomAlias.text.replaceAll("/#", ""))
                ?.queryParametersAll["via"] ??
            [],
      );

      showDialog(
        context: context,
        builder: (context) => ref
            .watch(
              RoomSummaryController.provider(
                .new(roomIdOrAlias: roomIdOrAlias, via: via),
              ),
            )
            .betterWhen(
              data: (summary) => RoomSummaryDialog(
                summary,
                extraActions: .new([
                  TextButton(
                    onPressed: () async {
                      // Capture everything before the dialog closes.
                      final container = ProviderScope.containerOf(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final colors = Theme.of(context).colorScheme;
                      Navigator.of(context).pop();

                      final snackbar = scaffoldMessenger.showSnackBar(
                        .new(
                          content: Text("Joining room $roomIdOrAlias."),
                          duration: Duration(days: 999),
                        ),
                      );

                      try {
                        final id = await container
                            .read(ClientController.provider.notifier)
                            .joinRoom(
                              .new(roomIdOrAlias: roomIdOrAlias, via: via),
                            );

                        snackbar.close();

                        scaffoldMessenger.showSnackBar(
                          .new(
                            content: Text(
                              "Room $roomIdOrAlias successfully joined.",
                            ),
                            action: .new(
                              label: "Open",
                              onPressed: () =>
                                  container.focusRoom(id).onError(showError),
                            ),
                          ),
                        );
                      } catch (error) {
                        snackbar.close();
                        scaffoldMessenger.showSnackBar(
                          .new(
                            backgroundColor: colors.errorContainer,
                            content: Text(
                              error.toString(),
                              style: .new(color: colors.onErrorContainer),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text("Join"),
                  ),
                ]),
              ),
              loading: () => Dialog(
                child: Row(
                  mainAxisAlignment: .center,
                  mainAxisSize: .min,
                  children: [
                    Padding(
                      padding: .all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
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
