import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:nexus/widgets/rooms/room_summary_sheet.dart";
import "package:nexus/widgets/users/user_bottom_sheet.dart";

import "helpers/matrix_user.dart";
import "helpers/test_app.dart";
import "helpers/pump_until.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final app = TestApp("dave", "davepass");
  setUpAll(app.setUp);
  final run = DateTime.now().millisecondsSinceEpoch;
  Future<MatrixUser> bob() => MatrixUser.login("bob", "bobpass");

  Future<void> openLink(WidgetTester tester, String link) async {
    await app.open(tester);
    app.fakes.links.open(.parse(link));
  }

  group("a link opened by the OS", () {
    testWidgets("to a user opens their popover", (tester) async {
      await openLink(tester, "matrix:u/bob:localhost");

      await tester.pumpUntil(find.byType(UserBottomSheet));
    });

    testWidgets("to a joined room opens it", (tester) async {
      final inviter = await bob();
      final roomId = await inviter.createRoom("Linked $run");
      // Joined before Nexus starts, so the room is there once it syncs
      await app.join(inviter, roomId);

      await openLink(tester, "matrix:roomid/${roomId.substring(1)}");

      await tester.pumpUntil(
        find.byWidgetPredicate(
          (widget) => widget is RoomChat && widget.roomId == roomId,
        ),
      );
    });

    testWidgets("to a room that isn't joined shows its summary", (
      tester,
    ) async {
      final roomId = await (await bob()).createRoom("Unjoined $run");

      await openLink(tester, "matrix:roomid/${roomId.substring(1)}");

      await tester.pumpUntil(find.byType(RoomSummarySheet));
    });
  });
}
