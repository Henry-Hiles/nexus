import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/message.dart";

extension IsMedia on Content {
  bool get isMedia => switch (this) {
    ImageMessageContent() ||
    VideoMessageContent() ||
    AudioMessageContent() ||
    FileMessageContent() => true,
    _ => false,
  };
}
