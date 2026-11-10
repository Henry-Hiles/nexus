import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/common/error_dialog.dart";

// Custom because `patrol_finder` gives me jQuery vibes, and that's Not GoodTM
extension PumpUntil on WidgetTester {
  /// Pumps until [finder] finds something, failing if it doesn't within 30
  /// seconds, or if the app shows an error.
  Future<void> pumpUntil(Finder finder) async {
    const timeout = Duration(seconds: 30);

    String textsIn(Finder finder) => widgetList<Text>(
      find.descendant(of: finder, matching: find.byType(Text)),
    ).map((text) => text.data).nonNulls.join("\n");

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      await pump(const .new(milliseconds: 100));

      if (finder.evaluate().isNotEmpty) return;

      final errorDialog = find.byType(ErrorDialog);
      if (errorDialog.evaluate().isNotEmpty) {
        fail(
          "The app showed an error while waiting for $finder:\n"
          "${textsIn(errorDialog)}",
        );
      }
    }

    final snackBar = find.byType(SnackBar);
    final shown = find
        .byType(RichText)
        .hitTestable()
        .evaluate()
        .map((element) => (element.widget as RichText).text.toPlainText())
        .where((text) => text.trim().isNotEmpty)
        .toIList()
        .removeDuplicates()
        .join(" | ");
    fail(
      "Timed out after $timeout waiting for $finder"
      "${snackBar.evaluate().isEmpty ? "" : "\nSnack bar: ${textsIn(snackBar)}"}"
      "\nShown: $shown",
    );
  }

  /// Taps [finder] once it can be tapped, like after animating in.
  Future<void> tapWhenShown(Finder finder) async {
    final tappable = finder.hitTestable();
    await pumpUntil(tappable);
    await tap(tappable.first);
    await pump();
  }
}
