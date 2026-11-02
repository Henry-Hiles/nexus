import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/event.dart";

extension IsShownAsMessage on Event {
  /// Whether this is a message, sticker or poll.
  bool get hasMessageContent => switch (content) {
    MessageContent() || StickerContent() || PollStartContent() => true,
    _ => false,
  };

  /// Whether this is shown in the timeline as a message, with MessageRenderer.
  bool get isShownAsMessage =>
      redactedBy == null &&
      relationType != "m.replace" &&
      (hasMessageContent || content is EncryptedContent);
}
