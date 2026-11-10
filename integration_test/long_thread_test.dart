import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:nexus/widgets/threads/thread_drawer.dart";
import "package:nexus/widgets/threads/threads_drawer.dart";

import "helpers/matrix_user.dart";
import "helpers/test_app.dart";
import "helpers/pump_until.dart";
import "helpers/threads.dart";

/// A thread longer than gomuks' initial sync, which gets the latest 100
/// events, so its start only reaches Nexus through `/relations`. That needs
/// an account whose first sync is after the thread exists, so it's not the one
/// other tests use.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final app = TestApp("carol", "carolpass");
  setUpAll(app.setUp);
  final run = DateTime.now().millisecondsSinceEpoch;
  final roomName = "Long thread $run";
  final rootBody = "Long thread root $run";
  const replyCount = 120;
  // Among the first replies, which aren't synced
  const jumpedTo = 10;
  // Padded, so no reply's text contains another's (oops those failures were confusing when I didn't do that)
  String reply(int number) => "Long reply ${number.toString().padLeft(3, "0")}";

  setUpAll(() async {
    final bob = await MatrixUser.login("bob", "bobpass");
    final roomId = await bob.createRoom(roomName);
    await app.join(bob, roomId);

    final thread = await bob.sendThread(
      roomId,
      rootBody,
      Iterable.generate(replyCount, (index) => reply(index + 1)).toIList(),
    );
    // In the room's timeline, so there's something to jump from, to a reply
    // with others on both sides that aren't synced either
    await bob.send(
      roomId,
      "Quoting an old reply",
      replyTo: thread.replyIds[jumpedTo - 1],
    );
  });

  /// Drags the open thread by [offset] until [finder] is shown in it, loading
  /// more replies as it goes, for up to 30 seconds.
  Future<void> scrollThread(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) => tester.dragUntilVisible(
    finder.inside(ThreadDrawer),
    find.byType(CustomScrollView).inside(ThreadDrawer).first,
    offset,
    maxIteration: 60,
    duration: const .new(milliseconds: 500),
  );

  Future<void> openThreadsDrawer(WidgetTester tester) async {
    await app.openRoom(tester, roomName);
    await tester.tapWhenShown(find.byTooltip("Open threads"));
    await tester.pumpUntil(find.message(rootBody).inside(ThreadsDrawer));
  }

  testWidgets("lists the thread with all of its replies", (tester) async {
    await openThreadsDrawer(tester);

    await tester.expectReplyCount(ThreadsDrawer, replyCount);
  });

  // Before the whole thread is loaded by scrolling through it below
  testWidgets("jumps to a reply in the thread that isn't loaded", (
    tester,
  ) async {
    await app.openRoom(tester, roomName);

    // The quote of the reply is fetched on its own, then tapped
    await tester.tapWhenShown(
      find.message(reply(jumpedTo)).inside(RoomChat).inkWell,
    );

    // The thread opens around the reply, with replies on both sides
    await tester.pumpUntil(
      find.message(reply(jumpedTo)).inside(ThreadDrawer).hitTestable(),
    );
    await tester.pumpUntil(
      find.message(reply(jumpedTo - 1)).inside(ThreadDrawer),
    );
    await tester.pumpUntil(
      find.message(reply(jumpedTo + 1)).inside(ThreadDrawer),
    );

    await scrollThread(tester, find.message(reply(60)), const .new(0, -400));
  });

  testWidgets("loads older replies back to the root", (tester) async {
    await openThreadsDrawer(tester);
    await tester.tapWhenShown(
      find.message(rootBody).inside(ThreadsDrawer).inkWell,
    );
    await tester.pumpUntil(
      find.message(reply(replyCount)).inside(ThreadDrawer),
    );

    // Dragging down scrolls up the reversed timeline, to older replies
    await scrollThread(tester, find.message(rootBody), const .new(0, 400));
    expect(find.message(reply(1)).inside(ThreadDrawer), findsWidgets);
  });
}
