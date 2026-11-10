import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/composer/composer.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:nexus/widgets/threads/thread_drawer.dart";
import "package:nexus/widgets/threads/thread_summary.dart";
import "package:nexus/widgets/threads/threads_drawer.dart";

import "helpers/matrix_user.dart";
import "helpers/test_app.dart";
import "helpers/pump_until.dart";
import "helpers/threads.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final app = TestApp("alice", "alicepass");
  setUpAll(app.setUp);
  final run = DateTime.now().millisecondsSinceEpoch;
  late MatrixUser bob;

  setUpAll(() async => bob = await MatrixUser.login("bob", "bobpass"));

  /// Opens [roomName], waiting for the thread from [rootBody] in its timeline.
  Future<void> openRoom(
    WidgetTester tester,
    String roomName,
    String rootBody,
  ) async {
    await app.openRoom(tester, roomName);
    await tester.pumpUntil(
      find.message(rootBody).inside(RoomChat).hitTestable(),
    );
  }

  /// Opens the thread from the room's summary, waiting for [reply] in it.
  Future<void> openThread(WidgetTester tester, String reply) async {
    await tester.tapWhenShown(find.byType(ThreadSummary));
    await tester.pumpUntil(find.message(reply).inside(ThreadDrawer));
  }

  group("a thread", () {
    final roomName = "Threads $run";
    final rootBody = "Thread root $run";
    const firstReply = "First reply";
    const secondReply = "Second reply";

    late String roomId;
    late String rootId;

    setUpAll(() async {
      roomId = await bob.createRoom(roomName);
      // Joined before Nexus logs in, so the room is there once it does
      await app.join(bob, roomId);

      rootId = (await bob.sendThread(
        roomId,
        rootBody,
        .new([firstReply, secondReply]),
      )).rootId;
    });

    Future<int> replyCount() async =>
        (await bob.threadReplies(roomId, rootId)).length;

    testWidgets("logs in with OAuth and sets up encryption", (tester) async {
      await app.open(tester);

      await app.selectRoom(tester, roomName);
    });

    testWidgets("summarises the thread under its root", (tester) async {
      await openRoom(tester, roomName, rootBody);

      await tester.expectReplyCount(ThreadSummary, 2);
      expect(find.message(secondReply).inside(ThreadSummary), findsWidgets);
      // Replies are in the thread, not the room's timeline
      expect(find.message(firstReply), findsNothing);
    });

    testWidgets("lists the thread in the threads drawer", (tester) async {
      await openRoom(tester, roomName, rootBody);
      await tester.tapWhenShown(find.byTooltip("Open threads"));

      await tester.pumpUntil(find.message(rootBody).inside(ThreadsDrawer));
      await tester.expectReplyCount(ThreadsDrawer, 2);
      expect(find.text("Last active:").inside(ThreadsDrawer), findsOneWidget);
    });

    testWidgets("opens the thread from the threads drawer", (tester) async {
      await openRoom(tester, roomName, rootBody);
      await tester.tapWhenShown(find.byTooltip("Open threads"));
      await tester.tapWhenShown(
        find.message(rootBody).inside(ThreadsDrawer).inkWell,
      );

      await tester.pumpUntil(find.message(secondReply).inside(ThreadDrawer));
    });

    testWidgets("shows the root and its replies, oldest first", (tester) async {
      await openRoom(tester, roomName, rootBody);
      await openThread(tester, secondReply);

      final root = find.message(rootBody).inside(ThreadDrawer).first;
      final first = find.message(firstReply).inside(ThreadDrawer).first;
      final second = find.message(secondReply).inside(ThreadDrawer).first;
      expect(root, findsOneWidget);
      expect(first, findsOneWidget);
      expect(
        tester.getTopLeft(root).dy,
        lessThan(tester.getTopLeft(first).dy),
        reason: "The root should be above the replies",
      );
      expect(
        tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(second).dy),
        reason: "Older replies should be above newer ones",
      );
    });

    testWidgets("sends replies to the thread", (tester) async {
      final body = "Reply from Nexus $run";
      final before = await replyCount();
      await openRoom(tester, roomName, rootBody);
      await openThread(tester, secondReply);

      final composer = find
          .widgetWithText(TextField, "Your message here...")
          .inside(ThreadDrawer);
      await tester.pumpUntil(composer);
      await tester.enterText(composer, body);
      await tester.tapWhenShown(
        find.byTooltip("Send message").inside(ThreadDrawer),
      );
      await tester.pumpUntil(find.message(body).inside(ThreadDrawer));

      // It's in the thread for other clients too
      final replies = await bob.threadRepliesIncluding(roomId, rootId, body);
      expect(replies.last, body);

      // Shown as the latest reply once the summary has caught up
      await tester.pumpUntil(find.message(body).inside(ThreadSummary));
      await tester.expectReplyCount(ThreadSummary, before + 1);
      expect(
        find.text(body).inside(Composer),
        findsNothing,
        reason: "The composer should be cleared once sent",
      );
    });

    testWidgets("shows replies from others as they arrive", (tester) async {
      final body = "Live reply $run";
      await openRoom(tester, roomName, rootBody);
      await openThread(tester, secondReply);

      final before = await replyCount();
      await bob.send(roomId, body, threadRoot: rootId);

      await tester.pumpUntil(find.message(body).inside(ThreadDrawer));
      await tester.pumpUntil(find.message(body).inside(ThreadSummary));
      await tester.expectReplyCount(ThreadSummary, before + 1);
    });
  });

  group("redactions", () {
    final roomName = "Redactions $run";
    final rootBody = "Redaction root $run";
    const keptReply = "Kept reply";
    const redactedReply = "Redacted reply";

    late String roomId;
    late String rootId;
    late String redactedId;

    setUpAll(() async {
      roomId = await bob.createRoom(roomName);
      await app.join(bob, roomId);

      final thread = await bob.sendThread(
        roomId,
        rootBody,
        .new([keptReply, redactedReply]),
      );
      rootId = thread.rootId;
      redactedId = thread.replyIds.last;
    });

    testWidgets("drops a redacted reply from its thread", (tester) async {
      await openRoom(tester, roomName, rootBody);
      await tester.expectReplyCount(ThreadSummary, 2);

      await bob.redact(roomId, redactedId);

      // The reply before it becomes the latest
      await tester.pumpUntil(find.message(keptReply).inside(ThreadSummary));
      await tester.expectReplyCount(ThreadSummary, 1);

      await openThread(tester, keptReply);
      expect(find.message(redactedReply).inside(ThreadDrawer), findsNothing);
    });

    testWidgets("still opens the thread of a redacted root", (tester) async {
      await bob.redact(roomId, rootId);
      await app.openRoom(tester, roomName);
      await tester.tapWhenShown(find.byTooltip("Open threads"));

      // The root's preview is redacted, so the card is found by its count
      await tester.tapWhenShown(
        find.text("1 reply").inside(ThreadsDrawer).inkWell,
      );

      final root = find.text("Redacted event").inside(ThreadDrawer);
      final reply = find.message(keptReply).inside(ThreadDrawer);
      await tester.pumpUntil(root);
      await tester.pumpUntil(reply);
      expect(
        tester.getTopLeft(root.first).dy,
        lessThan(tester.getTopLeft(reply.first).dy),
        reason: "The redacted root should still be above the replies",
      );
    });
  });

  group("edits", () {
    final roomName = "Edits $run";
    final rootBody = "Edit root $run";
    const originalReply = "Reply before editing";
    const editedReply = "Reply after editing";

    late String roomId;
    late String replyId;

    setUpAll(() async {
      roomId = await bob.createRoom(roomName);
      await app.join(bob, roomId);

      final thread = await bob.sendThread(
        roomId,
        rootBody,
        .new([originalReply]),
      );
      replyId = thread.replyIds.single;
    });

    testWidgets("shows an edited reply's new text", (tester) async {
      await openRoom(tester, roomName, rootBody);
      await tester.pumpUntil(find.message(originalReply).inside(ThreadSummary));

      await bob.edit(roomId, replyId, editedReply);

      await tester.pumpUntil(find.message(editedReply).inside(ThreadSummary));
      await openThread(tester, editedReply);
      expect(find.message(originalReply).inside(ThreadDrawer), findsNothing);
      expect(find.text("(edited)").inside(ThreadDrawer), findsOneWidget);
    });
  });
}
