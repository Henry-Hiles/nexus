import "package:app_links_platform_interface/app_links_platform_interface.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:media_kit/media_kit.dart";
import "package:nexus/controllers/active_account.dart";
import "package:nexus/main.dart" as nexus;
import "package:nexus/widgets/account_scope.dart";
import "package:nexus/widgets/pages/chat.dart";
import "package:nexus/widgets/pages/select_server.dart";
import "package:nexus/widgets/pages/verify.dart";
import "package:nexus/widgets/room_chat/room_chat.dart";
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";

import "matrix_user.dart";
import "oauth.dart";
import "pump_until.dart";

/// Nexus, run as the account [username], which is set up through the UI the
/// first time it's opened.
class TestApp(final String username, final String password) {
  late final fakes = OAuthFakes(username, password);

  void setUp() {
    nexus.isInBackground = false;
    MediaKit.ensureInitialized();
    AppLinksPlatform.instance = fakes.links;
    UrlLauncherPlatform.instance = fakes.launcher;

    // A tap that misses would otherwise only warn
    WidgetController.hitTestWarningShouldBeFatal = true;
  }

  Future<void> join(MatrixUser inviter, String roomId) async {
    final user = await MatrixUser.login(username, password);
    await inviter.invite(roomId, user.userId);
    await user.join(roomId);
    await user.logout();
  }

  /// Starts Nexus like [open], then opens [roomName].
  Future<void> openRoom(WidgetTester tester, String roomName) async {
    await open(tester);
    await selectRoom(tester, roomName);
  }

  /// Taps [roomName] in the room list, opening the drawer it's in first when
  /// the window is narrow enough for the mobile layout.
  Future<void> selectRoom(WidgetTester tester, String roomName) async {
    // Shown once the first sync is done, as is the drawer button on mobile
    await tester.pumpUntil(find.byType(RoomChat));

    final drawerButton = find
        .byTooltip(const DefaultMaterialLocalizations().openAppDrawerTooltip)
        .hitTestable();
    if (drawerButton.evaluate().isNotEmpty) await tester.tap(drawerButton);
    await tester.tapWhenShown(find.text(roomName));
  }

  /// Starts Nexus, logged in and verified, logging in and setting up
  /// encryption through the UI first if it isn't.
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      AccountScope(
        initialAccountId: await ActiveAccountController.stored(),
        retry: (_, _) => null,
        child: nexus.App(),
      ),
    );

    await tester.pumpUntil(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectServerPage ||
            widget is VerifyPage ||
            widget is ChatPage,
      ),
    );
    if (find.byType(SelectServerPage).evaluate().isNotEmpty) {
      await logIn(tester);
    }
    if (find.byType(VerifyPage).evaluate().isNotEmpty) {
      await setUpEncryption(tester);
    }
    await tester.pumpUntil(find.byType(ChatPage));
  }

  Future<void> logIn(WidgetTester tester) async {
    final homeserverField = find.widgetWithText(TextField, "Homeserver URL");
    await tester.pumpUntil(homeserverField);
    await tester.enterText(homeserverField, homeserver);
    await tester.testTextInput.receiveAction(.done);

    // Discovery only uses HTTPS, which the test homeserver doesn't serve, so
    // Nexus offers to log in with the URL as typed
    await tester.tapWhenShown(find.text("Attempt log in anyways"));

    // Nexus opens the authorization page, which fakes authorizes
    await tester.pumpUntil(
      find.byWidgetPredicate(
        (widget) => widget is VerifyPage || widget is ChatPage,
      ),
    );
  }

  /// Sets up encryption from the verify page, for an account without it.
  Future<void> setUpEncryption(WidgetTester tester) async {
    await tester.pumpUntil(find.text("Set Up Encryption"));
    await tester.tapWhenShown(find.widgetWithText(TextButton, "Set Up"));

    await tester.tapWhenShown(find.text("I've saved my recovery key"));
    await tester.tapWhenShown(find.widgetWithText(TextButton, "Set Up"));

    await tester.tapWhenShown(find.widgetWithText(TextButton, "Done"));
  }
}
