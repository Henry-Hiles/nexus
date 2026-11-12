import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/gomuks_listener.dart";
import "package:nexus/controllers/init_complete.dart";
import "package:nexus/controllers/key.dart";
import "package:nexus/controllers/member_list_opened.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/space_edges.dart";
import "package:nexus/controllers/top_level_spaces.dart";
import "package:nexus/main.dart" as nexus;
import "package:nexus/models/account.dart";
import "package:nexus/widgets/account_scope.dart";
import "package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart";
import "package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart";

import "../helpers/pump_until.dart";
import "screenshot_data.dart";
import "screenshot_fakes.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Where the screenshots are saved, set by `nix run .#screenshots`
  const outputDirectory = String.fromEnvironment(
    "SCREENSHOTS_DIR",
    defaultValue: "build/screenshots",
  );
  const accountId = "screenshots";

  final data = ScreenshotData(.now());

  setUpAll(() => nexus.isInBackground = false);

  /// Opens Nexus at the Nexus room, as a [size] window at [pixelRatio],
  /// pretending to be a phone if [mobile].
  Future<void> open(
    WidgetTester tester, {
    required ThemeMode theme,
    required Size size,
    required double pixelRatio,
    required bool mobile,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          KeyController.accountsKey: json.encode([
            Account(
              id: accountId,
              userId: ScreenshotData.me,
              displayName: "QuadRadical",
              avatar: .parse(ScreenshotData.myAvatar),
            ),
          ]),
          KeyController.activeAccountKey: accountId,
          MemberListOpenedController.key: true,
          "$accountId/${KeyController.spaceKey}": ScreenshotData.nexusSpace,
          "$accountId/${KeyController.roomKey}": ScreenshotData.nexusRoom,
        });

    await tester.pumpWidget(
      AccountScope(
        initialAccountId: accountId,
        retry: (_, _) => null,
        overrides: [
          ClientController.provider.overrideWith(FakeClientController.new),
          // Never starts gomuks; the state below is what it would sync
          GomuksListenerController.provider.overrideWithBuild((_, _) {}),
          ClientStateController.provider.overrideWithBuild(
            (_, _) => ScreenshotData.clientState,
          ),
          InitCompleteController.provider.overrideWithBuild((_, _) => true),
          RoomsController.provider.overrideWithBuild((_, _) => data.rooms),
          TopLevelSpacesController.provider.overrideWithBuild(
            (_, _) => ScreenshotData.topLevelSpaces,
          ),
          SpaceEdgesController.provider.overrideWithBuild(
            (_, _) => ScreenshotData.spaceEdges,
          ),
          SettingsController.provider.overrideWithBuild(
            (_, _) => .new(
              theme: theme,
              useDynamicTheming: false,
              linuxMobileMode: mobile,
            ),
          ),
        ],
        child: nexus.App(),
      ),
    );

    await tester.pumpUntil(find.text("they're generated now?? let's gooo"));

    // Focused on desktop, which would show a cursor
    FocusManager.instance.primaryFocus?.unfocus();
  }

  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets("desktop, ${theme.name}", (tester) async {
      await open(
        tester,
        theme: theme,
        size: const .new(1920, 1080),
        pixelRatio: 1,
        mobile: false,
      );

      await tester.pumpUntil(find.text("Strudel"));

      await tester.screenshot("$outputDirectory/desktop-${theme.name}.png");
    });

    testWidgets("phone, ${theme.name}", (tester) async {
      await open(
        tester,
        theme: theme,
        size: const .new(1080, 2340),
        pixelRatio: 3,
        mobile: true,
      );

      await tester.screenshot("$outputDirectory/phone-chat-${theme.name}.png");

      await tester.tap(
        find.byTooltip(
          const DefaultMaterialLocalizations().openAppDrawerTooltip,
        ),
      );
      await tester.pumpUntil(find.text("Off-topic"));

      await tester.screenshot("$outputDirectory/phone-rooms-${theme.name}.png");
    });
  }
}
