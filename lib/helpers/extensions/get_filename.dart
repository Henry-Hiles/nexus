import "package:nexus/models/content/message.dart";

extension GetFilename on MessageContent {
  String? get filename => switch (this) {
    ImageMessageContent(:final filename) ||
    VideoMessageContent(:final filename) ||
    AudioMessageContent(:final filename) ||
    FileMessageContent(:final filename) => filename,
    _ => null,
  };
}
