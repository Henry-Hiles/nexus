import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "pump_until.dart";

extension MessageFinders on CommonFinders {
  Finder message(String body) => textContaining(body, findRichText: true);
}

extension RelativeFinders on Finder {
  Finder inside(Type type) =>
      find.descendant(of: find.byType(type), matching: this);

  /// The [InkWell] ancestor around what this finds
  Finder get inkWell => find.ancestor(of: this, matching: find.byType(InkWell));
}

extension ReplyCounts on WidgetTester {
  /// Waits for a reply count in widgets of [type], then checks it, so a wrong
  /// count fails straight away with what was shown.
  Future<void> expectReplyCount(Type type, int expected) async {
    final repliesLabel = RegExp(r"^(\d+) repl(?:y|ies)$");
    final labels = find.textContaining(repliesLabel).inside(type);
    await pumpUntil(labels);

    final shown = widgetList<Text>(labels)
        .map((label) => label.data)
        .nonNulls
        .map(repliesLabel.firstMatch)
        .nonNulls
        .map((match) => int.parse(match[1]!));
    expect(shown, everyElement(expected), reason: "Reply count in $type");
  }
}
