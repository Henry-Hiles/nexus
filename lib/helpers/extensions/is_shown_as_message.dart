import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/event.dart";

extension IsShownAsMessage on Event {
  /// Whether this is shown in the timeline as a message, with MessageRenderer.
  bool get isShownAsMessage =>
      redactedBy == null &&
      relationType != "m.replace" &&
      switch (content) {
        MessageContent() || EncryptedContent() || StickerContent() => true,
        _ => false,
      };
}
