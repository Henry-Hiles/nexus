import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:linkify/linkify.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/event_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_event_request.dart";
import "package:nexus/widgets/file_card.dart";
import "package:nexus/widgets/html/html.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/linkified_text.dart";
import "package:nexus/widgets/message_image.dart";
import "package:nexus/widgets/reaction_row.dart";
import "package:nexus/widgets/url_preview.dart";
import "package:timeago/timeago.dart";
import "package:nexus/widgets/event_preview.dart";
import "package:nexus/widgets/players/video.dart";
import "package:nexus/widgets/players/audio.dart";

class MessageRenderer extends ConsumerWidget {
  final Event event;
  final bool textOnly;
  final bool isGrouped;
  final int? maxLines;
  final VoidCallback? onTapReply;
  const MessageRenderer(
    this.event, {
    this.onTapReply,
    this.textOnly = false,
    this.isGrouped = false,
    this.maxLines,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorStyle = TextStyle(color: colorScheme.error);

    final timestamp = Tooltip(
      message: event.timestamp.toString(),
      child: Text(
        format(event.timestamp),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
      ),
    );

    final textStyle = TextStyle(
      fontSize: event.localContent?.bigEmoji == true ? 32 : null,
      fontStyle: event.content is EmoteMessageContent ? FontStyle.italic : null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (!textOnly)
          if (isGrouped)
            SizedBox(width: 40)
          else
            MessageAvatar(event, height: 40),
        Flexible(
          child: Column(
            spacing: 4,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isGrouped && !textOnly)
                Row(
                  spacing: 4,
                  children: [
                    Flexible(child: MessageDisplayname(event)),
                    Flexible(flex: 0, child: timestamp),
                  ],
                ),
              Card(
                margin: textOnly ? EdgeInsets.zero : EdgeInsets.only(bottom: 4),
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
                  padding: textOnly ? EdgeInsets.zero : EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!textOnly && event.replyTo != null)
                        Card(
                          margin: EdgeInsets.only(bottom: 8),
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: InkWell(
                            onTap: onTapReply,
                            child: Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              child: switch (ref.watch(
                                EventController.provider(
                                  GetEventRequest(
                                    roomId: event.roomId,
                                    eventId: event.replyTo!,
                                  ),
                                ),
                              )) {
                                AsyncData(:final value?) ||
                                AsyncLoading(
                                  :final value?,
                                ) => EventPreview(value),
                                AsyncError _ => Text(
                                  "An error occurred while fetching the reply",
                                  style: errorStyle,
                                ),
                                _ => Text("Fetching event..."),
                              },
                            ),
                          ),
                        ),
                      switch (event.content) {
                        EncryptedContent() => Text(
                          "Unable to decrypt event",
                          style: errorStyle,
                        ),
                        StickerContent(:final url, :final info) =>
                          ConstrainedBox(
                            constraints: BoxConstraints.loose(Size.square(200)),
                            child: MessageImage(
                              url.mxcToHttps(
                                ref.watch(
                                  ClientStateController.provider.select(
                                    (value) => value!.homeserverUrl!,
                                  ),
                                ),
                              ),
                              info: info,
                            ),
                          ),
                        // TODO: Handle locations
                        // LocationMessageContent(:final body , :final geoUri) =>
                        TextMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        NoticeMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        EmoteMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        ImageMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        VideoMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        AudioMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) ||
                        FileMessageContent(
                          :final body,
                          :final formattedBody,
                          :final format,
                        ) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            format == MessageFormat.html && !textOnly
                                ? Html(
                                    roomId: event.roomId,
                                    textStyle: textStyle,
                                    formattedBody!.replaceAllMapped(
                                      RegExp(
                                        r"(<a\b[^>]*>.*?<\/a>)|(\bhttps?:\/\/[^\s<]+)",
                                        caseSensitive: false,
                                        dotAll: true,
                                      ),
                                      (m) {
                                        // If it's already an <a> tag, leave it unchanged
                                        if (m.group(1) != null) {
                                          return m.group(1)!;
                                        }

                                        // Otherwise, wrap the bare URL
                                        final url = m.group(2)!;
                                        return "<a href=\"$url\">$url</a>";
                                      },
                                    ),
                                  )
                                : LinkifiedText(
                                    body,
                                    style: textStyle,
                                    maxLines: maxLines,
                                  ),

                            if (!textOnly) ...[
                              if (event.content
                                  case ImageMessageContent(:final url) ||
                                      FileMessageContent(:final url) ||
                                      VideoMessageContent(:final url) ||
                                      AudioMessageContent(:final url))
                                switch (url?.mxcToHttps(
                                  ref.watch(
                                    ClientStateController.provider.select(
                                      (value) => value!.homeserverUrl!,
                                    ),
                                  ),
                                )) {
                                  final url? => ConstrainedBox(
                                    constraints: BoxConstraints.loose(
                                      Size.square(500),
                                    ),
                                    child: switch (event.content) {
                                      VideoMessageContent(:final info) =>
                                        VideoPlayer(url, info),
                                      AudioMessageContent(:final info) =>
                                        AudioPlayer(url, info),
                                      FileMessageContent(
                                        :final info,
                                        :final filename,
                                      ) =>
                                        FileCard(url, info, filename: filename),
                                      ImageMessageContent(:final info) =>
                                        MessageImage(url, info: info),
                                      _ => SizedBox.shrink(),
                                    },
                                  ),
                                  _ => Text(
                                    "Nexus currently cannot handle encrypted media",
                                    style: errorStyle,
                                  ),
                                },

                              if (event.lastEditRowId != 0)
                                Text(
                                  "(edited)",
                                  style: theme.textTheme.labelSmall,
                                ),

                              if (linkify(body).firstWhereOrNull(
                                    (element) => element is UrlElement,
                                  )
                                  case final UrlElement link?)
                                UrlPreview(link.url),

                              SizedBox(height: 4),
                              ReactionRow(event),
                            ],
                          ],
                        ),
                        MessageContent(:final body) => Row(
                          spacing: 8,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Unknown message type:", style: errorStyle),
                            Text(body),
                          ],
                        ),
                        _ => throw Exception("This is impossible"),
                      },
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
