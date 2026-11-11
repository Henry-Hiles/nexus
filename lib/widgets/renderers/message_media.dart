import "package:material_ui/material_ui.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/widgets/players/audio.dart";
import "package:nexus/widgets/players/video.dart";
import "package:nexus/widgets/renderers/file_card.dart";
import "package:nexus/widgets/renderers/message_image.dart";

final class const MessageMedia(final MessageContent content, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (content) {
    VideoMessageContent(
      :final url,
      :final info,
      :final file,
      :final filename,
      :final body,
    ) =>
      VideoPlayer(
        url,
        info,
        encrypted: file != null,
        filename: filename ?? body,
      ),
    AudioMessageContent(
      :final url,
      :final info,
      :final file,
      :final filename,
      :final body,
    ) =>
      AudioPlayer(
        url,
        info,
        encrypted: file != null,
        filename: filename ?? body,
      ),
    FileMessageContent(:final url, :final info, :final filename, :final file) =>
      FileCard(url, info, filename: filename, encrypted: file != null),
    ImageMessageContent(
      :final url,
      :final info,
      :final file,
      :final filename,
      :final body,
    ) =>
      MessageImage(
        url,
        info: info,
        encrypted: file != null,
        filename: filename ?? body,
      ),
    _ => SizedBox.shrink(),
  };
}
