import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:linkify/linkify.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/helpers/extensions/get_filename.dart";
import "package:nexus/helpers/extensions/linkify_html.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/location.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/file_card.dart";
import "package:nexus/widgets/html/html.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/common/linkified_text.dart";
import "package:nexus/widgets/location/location_message.dart";
import "package:nexus/widgets/common/loading.dart";
import "package:nexus/widgets/renderers/message_image.dart";
import "package:nexus/widgets/reactions/reaction_row.dart";
import "package:nexus/widgets/common/timestamp.dart";
import "package:nexus/widgets/renderers/url_preview.dart";
import "package:nexus/widgets/renderers/event_preview.dart";
import "package:nexus/widgets/players/video.dart";
import "package:nexus/widgets/players/audio.dart";
import "package:nexus/widgets/renderers/poll.dart";
import "package:nexus/widgets/threads/thread_summary.dart";

class const MessageRenderer(
  final Event event, {
  final VoidCallback? onTapReply,

  /// If set, thread roots show a summary of their thread, calling this when
  /// tapped.
  final VoidCallback? onTapThread,
  final bool textOnly = false,
  final bool isGrouped = false,
  final int? maxLines,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorStyle = TextStyle(color: colorScheme.error);

    final textStyle = TextStyle(
      fontSize: event.localContent?.bigEmoji == true && maxLines != 1
          ? 32
          : null,
      fontStyle: event.content is EmoteMessageContent ? .italic : null,
    );

    final rendered = switch (event.content) {
      _ when event.redactedBy != null => Text(
        "Redacted event",
        style: errorStyle,
      ),
      EncryptedContent() => Text("Unable to decrypt event", style: errorStyle),
      StickerContent(:final body, :final url, :final info) =>
        textOnly
            ? Text(body, maxLines: maxLines, overflow: .ellipsis)
            : ConstrainedBox(
                constraints: .loose(.square(200)),
                child: MessageImage(url, info: info, encrypted: false),
              ),
      PollStartContent(:final poll) =>
        textOnly
            ? Text(
                "Poll: ${poll.question}",
                maxLines: maxLines,
                overflow: .ellipsis,
              )
            : PollRenderer(event, poll),
      MessageContent content => switch (content) {
        final LocationMessageContent location =>
          textOnly
              ? Text(
                  switch (location.description) {
                    final description? => "Location: $description",
                    null => "Location",
                  },
                  maxLines: maxLines,
                  overflow: .ellipsis,
                )
              : LocationMessage(location),
        TextMessageContent(:final body, :final formattedBody, :final format) ||
        NoticeMessageContent(
          :final body,
          :final formattedBody,
          :final format,
        ) ||
        EmoteMessageContent(:final body, :final formattedBody, :final format) ||
        ImageMessageContent(:final body, :final formattedBody, :final format) ||
        VideoMessageContent(:final body, :final formattedBody, :final format) ||
        AudioMessageContent(:final body, :final formattedBody, :final format) ||
        FileMessageContent(
          :final body,
          :final formattedBody,
          :final format,
        ) => Column(
          crossAxisAlignment: .start,
          children: [
            textOnly
                ? Text(
                    body.isEmpty ? content.filename ?? "" : body,
                    style: textStyle,
                    maxLines: maxLines,
                    overflow: maxLines == null ? null : .ellipsis,
                  )
                : format == .html && formattedBody != null
                ? Html(
                    roomId: event.roomId,
                    textStyle: textStyle,
                    formattedBody.linkifiedHtml,
                  )
                : LinkifiedText(
                    body.isEmpty ? content.filename ?? "" : body,
                    roomId: event.roomId,
                    style: textStyle,
                    maxLines: maxLines,
                  ),

            if (!textOnly) ...[
              if (event.content
                  case ImageMessageContent(:final url) ||
                      FileMessageContent(:final url) ||
                      VideoMessageContent(:final url) ||
                      AudioMessageContent(:final url))
                ConstrainedBox(
                  constraints: .loose(.square(500)),
                  child: switch (event.content) {
                    VideoMessageContent(
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
                    FileMessageContent(
                      :final info,
                      :final filename,
                      :final file,
                    ) =>
                      FileCard(
                        url,
                        info,
                        filename: filename,
                        encrypted: file != null,
                      ),
                    ImageMessageContent(
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
                  },
                ),

              if (event.lastEditRowId != 0)
                Text("(edited)", style: theme.textTheme.labelSmall),

              if (linkify(body)
                      .firstWhereOrNull((element) => element is UrlElement)
                  case final UrlElement link?)
                if (Uri.tryParse(link.url) case final Uri url?) UrlPreview(url),
            ],
          ],
        ),
        UnknownMessageContent(:final body) =>
          body == null
              ? Text("This message is redacted", style: errorStyle)
              : Wrap(
                  spacing: 8,
                  children: [
                    Text("Unknown message type:", style: errorStyle),
                    Text(body),
                  ],
                ),
      },
      _ => throw Exception("This is impossible"),
    };

    return Row(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 6,
      children: [
        if (!textOnly)
          if (isGrouped)
            SizedBox(width: 40)
          else
            MessageAvatar(event, height: 40),
        Flexible(
          child: Column(
            spacing: 2,
            crossAxisAlignment: .start,
            children: [
              if (!isGrouped && !textOnly)
                Row(
                  spacing: 4,
                  children: [
                    Flexible(child: MessageDisplayname(event)),
                    Flexible(flex: 0, child: Timestamp(event.timestamp)),
                  ],
                ),
              Card(
                margin: textOnly ? .zero : .only(bottom: 4),
                color: textOnly
                    ? Colors.transparent
                    : ref.watch(
                            ClientStateController.provider.select(
                              (value) => value?.userId,
                            ),
                          ) ==
                          event.sender
                    ? (event.eventId.startsWith("~")
                          ? colorScheme.onPrimary
                          : colorScheme.primaryContainer)
                    : colorScheme.surfaceContainer,
                elevation: textOnly ? 0 : null,

                child: Padding(
                  padding: textOnly ? .zero : .all(12),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (!textOnly && event.replyTo != null)
                        Card(
                          margin: .only(bottom: 8),
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: InkWell(
                            onTap: onTapReply,
                            child: Padding(
                              padding: .symmetric(vertical: 8, horizontal: 12),
                              child: SizedBox(
                                // Two lines of text, plus EventPreview's padding
                                height:
                                    MediaQuery.textScalerOf(context).scale(40) +
                                    8,
                                child: switch (ref.watch(
                                  EventController.provider(
                                    .new(
                                      roomId: event.roomId,
                                      eventId: event.replyTo!,
                                    ),
                                  ),
                                )) {
                                  AsyncData(:final value?) ||
                                  AsyncLoading(:final value?) => EventPreview(
                                    value,
                                    roomId: event.roomId,
                                  ),
                                  AsyncError _ => Text(
                                    "An error occurred while fetching the reply",
                                    style: errorStyle,
                                  ),
                                  _ => Loading(dimension: 12),
                                },
                              ),
                            ),
                          ),
                        ),
                      rendered,
                      if (!textOnly) ReactionRow(event),
                      if (onTapThread case final onTapThread? when !textOnly)
                        ThreadSummary(event, onTap: onTapThread),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
