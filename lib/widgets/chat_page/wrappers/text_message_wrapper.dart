import "package:cross_cache/cross_cache.dart";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_link_previewer/flutter_link_previewer.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/controllers/url_preview_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/widgets/chat_page/html/html.dart";
import "package:nexus/widgets/chat_page/wrappers/message_wrapper.dart";
import "package:nexus/widgets/chat_page/reply_widget.dart";

class TextMessageWrapper extends ConsumerWidget {
  final Message message;
  final String? content;
  final MessageGroupStatus? groupStatus;
  final Future<void> Function(Message oldMessage, Message newMessage)
  updateMessage;
  final bool isSentByMe;
  final Widget? extra;
  final OnTapReply onTapReply;

  const TextMessageWrapper(
    this.message, {
    this.content,
    this.onTapReply,
    required this.updateMessage,
    required this.groupStatus,
    required this.isSentByMe,
    this.extra,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textMessage = message is TextMessage ? message as TextMessage : null;

    return MessageWrapper(
      message,
      ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSentByMe
                ? (message.id.startsWith("~")
                      ? colorScheme.onPrimary
                      : colorScheme.primaryContainer)
                : colorScheme.surfaceContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReplyWidget(
                message,
                groupStatus: groupStatus,
                onTapReply: onTapReply,
              ),
              if (content != null)
                message.metadata?["format"] == "org.matrix.custom.html"
                    ? Html(
                        textStyle: message.metadata?["big"] == true
                            ? TextStyle(fontSize: 32)
                            : null,
                        content!.replaceAllMapped(
                          RegExp(
                            "(<a\\b[^>]*>.*?<\\/a>)|(\\bhttps?:\\/\\/[^\\s<]+)",
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
                        text: content!,
                        options: LinkifyOptions(humanize: false),
                        onOpen: (link) => ref
                            .watch(LaunchHelper.provider)
                            .launchUrl(Uri.parse(link.url)),
                        linkStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              if (textMessage?.editedAt != null)
                Text("(edited)", style: theme.textTheme.labelSmall),
              if (textMessage != null)
                ref
                    .watch(UrlPreviewController.provider(textMessage))
                    .betterWhen(
                      loading: SizedBox.shrink,
                      data: (preview) => preview == null
                          ? SizedBox.shrink()
                          : LinkPreview(
                              imageBuilder: (url) => Image(
                                image: CachedNetworkImage(
                                  url,
                                  ref.watch(CrossCacheController.provider),
                                  headers: ref.headers,
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => SizedBox.shrink(),
                              ),
                              text: textMessage.text,
                              backgroundColor: isSentByMe
                                  ? colorScheme.inversePrimary
                                  : colorScheme.surfaceContainerLow,
                              outsidePadding: EdgeInsets.only(top: 4),
                              insidePadding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              linkPreviewData: preview,
                              onLinkPreviewDataFetched: (_) => null,
                            ),
                    ),
              if (extra != null) extra!,
            ],
          ),
        ),
      ),
      groupStatus,
    );
  }
}
