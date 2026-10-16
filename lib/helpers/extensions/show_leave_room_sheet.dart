import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/widgets/sheet_layout.dart";

extension ShowLeaveRoomSheet on BuildContext {
  /// Asks the user to confirm leaving the room, then leaves it.
  Future<void> showLeaveRoomSheet(String roomId, {required String name}) =>
      showAdaptiveSheet(
        (context) => SheetLayout(
          title: const Text("Leave Room"),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final client = ProviderScope.containerOf(
                  context,
                ).read(ClientController.provider.notifier);
                context.withProgressSnackbar(
                  "Leaving $name...",
                  () => client.leaveRoom(roomId),
                );
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text("Leave"),
            ),
          ],
          children: [Text("Are you sure you want to leave \"$name\"?")],
        ),
      );
}
