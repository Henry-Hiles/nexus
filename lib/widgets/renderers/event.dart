import "package:collection/collection.dart";
import "package:cross_cache/cross_cache.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_blurhash/flutter_blurhash.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:linkify/linkify.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/event_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/requests/get_event_request.dart";
import "package:nexus/widgets/event_preview.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/html/html.dart";
import "package:nexus/widgets/lazy_loading/message_avatar.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/url_preview.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/players/video.dart";
import "package:nexus/widgets/players/audio.dart";
import "package:nexus/widgets/reaction_row.dart";
import "package:nexus/widgets/renderers/membership.dart";
import "package:nexus/widgets/renderers/generic_event.dart";
import "package:nexus/widgets/file_card.dart";
import "package:timeago/timeago.dart";
import "package:flutter_linkify/flutter_linkify.dart";

class EventRenderer extends ConsumerWidget {
  final Event event;
  final bool textOnly;
  final bool isGrouped;
  final int? maxLines;
  final VoidCallback? onTapReply;
  final IList<PopupMenuEntry> Function(Event event)? getEventOptions;
  const EventRenderer(
    this.event, {
    this.onTapReply,
    this.textOnly = false,
    this.isGrouped = false,
    this.maxLines,
    this.getEventOptions,
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
    final contextMenuCallback = getEventOptions == null
        ? null
        : (details) => context.showContextMenu(
            globalPosition: details.globalPosition,
            children: getEventOptions!(event).toList(),
          );

    final textStyle = TextStyle(
      fontSize: event.localContent?.bigEmoji == true ? 32 : null,
      fontStyle: event.content is EmoteMessageContent ? FontStyle.italic : null,
    );

    final child = event.redactedBy != null || event.relationType == "m.replace"
        ? null
        : switch (event.content) {
            Content(:final parseError?) => SelectableText(
              "An error occurred while parsing this event:\n$parseError\n${parseError.stackTrace}",
              style: errorStyle,
            ),
            MessageContent() || EncryptedContent() => Row(
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
                        margin: textOnly
                            ? EdgeInsets.zero
                            : EdgeInsets.only(bottom: 4),
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
                          padding: textOnly
                              ? EdgeInsets.zero
                              : EdgeInsets.all(12),
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
                                        : Linkify(
                                            style: textStyle,
                                            text: body,
                                            maxLines: maxLines,
                                            overflow: maxLines == null
                                                ? null
                                                : TextOverflow.ellipsis,
                                            options: LinkifyOptions(
                                              humanize: false,
                                            ),
                                            onOpen: (link) => ref
                                                .watch(LaunchHelper.provider)
                                                .launchUrl(Uri.parse(link.url)),
                                            linkStyle: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),

                                    if (!textOnly) ...[
                                      if (event.content
                                          case ImageMessageContent(
                                                :final url,
                                              ) ||
                                              FileMessageContent(:final url) ||
                                              VideoMessageContent(:final url) ||
                                              AudioMessageContent(:final url))
                                        switch (url?.mxcToHttps(
                                          ref.watch(
                                            ClientStateController.provider
                                                .select(
                                                  (value) =>
                                                      value!.homeserverUrl!,
                                                ),
                                          ),
                                        )) {
                                          final url? => ConstrainedBox(
                                            constraints: BoxConstraints.loose(
                                              Size.square(500),
                                            ),
                                            child: switch (event.content) {
                                              VideoMessageContent(
                                                :final info,
                                              ) =>
                                                VideoPlayer(url, info),
                                              AudioMessageContent(
                                                :final info,
                                              ) =>
                                                AudioPlayer(url, info),
                                              FileMessageContent(
                                                :final info,
                                                :final filename,
                                              ) =>
                                                FileCard(
                                                  url,
                                                  info,
                                                  filename: filename,
                                                ),
                                              ImageMessageContent(:final info) => ExpandableImage(
                                                url.toString(),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                  child: Image(
                                                    image: CachedNetworkImage(
                                                      url.toString(),
                                                      ref.watch(
                                                        CrossCacheController
                                                            .provider,
                                                      ),
                                                      headers: ref.headers,
                                                    ),
                                                    width: info?.width,
                                                    loadingBuilder:
                                                        (
                                                          _,
                                                          child,
                                                          loadingProgress,
                                                        ) => loadingProgress == null
                                                        ? child
                                                        : switch (info?.blurHash) {
                                                            final blurHash? =>
                                                              info?.width ==
                                                                          null ||
                                                                      info?.height ==
                                                                          null
                                                                  ? SizedBox(
                                                                      width:
                                                                          200,
                                                                      height:
                                                                          200,
                                                                      child: BlurHash(
                                                                        hash:
                                                                            blurHash,
                                                                      ),
                                                                    )
                                                                  : AspectRatio(
                                                                      aspectRatio:
                                                                          info!
                                                                              .width! /
                                                                          info.height!,
                                                                      child: SizedBox(
                                                                        width: info
                                                                            .width,
                                                                        child: BlurHash(
                                                                          hash:
                                                                              blurHash,
                                                                        ),
                                                                      ),
                                                                    ),
                                                            _ => Loading(),
                                                          },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Text(
                                                            "Image Failed to Load",
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                context,
                                                              ).colorScheme.error,
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ),
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
                                    Text(
                                      "Unknown message type:",
                                      style: errorStyle,
                                    ),
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
            ),
            MembershipContent content =>
              event.previousContent is MembershipContent &&
                      (event.previousContent as MembershipContent).status ==
                          content.status
                  ? null
                  : MembershipRenderer(event),
            AvatarContent() => GenericEventRenderer(Icons.numbers, [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.numbers),
              ),
              Flexible(child: MessageDisplayname(event)),
              Expanded(child: Text("changed the room avatar")),
            ]),
            _ => null,
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (child != null) ...[
          if (textOnly)
            child
          else
            GestureDetector(
              onSecondaryTapUp: contextMenuCallback,
              onLongPressStart: contextMenuCallback,
              child: Padding(
                padding: isGrouped ? EdgeInsets.zero : EdgeInsets.only(top: 8),
                child: child,
              ),
            ),

          if (event.content is! MessageContent)
            Padding(
              padding: EdgeInsetsGeometry.only(left: 12),
              child: ReactionRow(event),
            ),

          if (event.sendError != null && event.sendError != "not sent")
            Text(
              event.sendError!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ] else if (textOnly)
          Text("Unknown event type", style: errorStyle),
      ],
    );
  }
}
