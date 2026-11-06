import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

enum TextCommandGroup { messageType, format }

// Prefixes gomuks parses out of sent text, in the order it expects them
enum TextCommand(final String description, {final TextCommandGroup? group}) {
  me("Send as an emote", group: .messageType),
  notice("Send as a notice", group: .messageType),
  unencrypted("Send unencrypted, even if the room is encrypted"),
  rawinputbody("Use the text as the body as-is, rather than from the HTML"),
  plain("Send without any formatting", group: .format),
  html("Send with only HTML, without markdown", group: .format),
  htmlmd("Send with both HTML and markdown", group: .format),
  rainbow("Send in rainbow colors, with markdown", group: .format);

  String get prefix => "/$name";

  bool completes(String text) =>
      text.startsWith("/") && prefix.startsWith(text.toLowerCase());

  // Replaces any command from the same group, as gomuks only uses one
  IList<TextCommand> addTo(IList<TextCommand> commands) => .new(
    commands
        .where(
          (other) => other != this && (group == null || other.group != group),
        )
        .toIList()
        .add(this)
        .sortedBy((command) => command.index),
  );

  static String prefixOf(IList<TextCommand> commands) =>
      commands.map((command) => "${command.prefix} ").join();

  static ({IList<TextCommand> commands, String text}) parse(
    String text, [
    IList<TextCommand> commands = const .empty(),
  ]) => switch (values.firstWhereOrNull(
    (command) => text.toLowerCase().startsWith("${command.prefix} "),
  )) {
    final command? => parse(
      text.substring(command.prefix.length + 1),
      command.addTo(commands),
    ),
    null => (commands: commands, text: text),
  };
}
