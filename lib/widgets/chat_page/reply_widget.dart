import "dart:math";
import "package:flutter/material.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/event_controller.dart";
import "package:nexus/controllers/message_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/models/message_config.dart";
import "package:nexus/models/requests/get_event_request.dart";
import "package:nexus/models/room.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/chat_page/html/quoted.dart";

typedef OnTapReply = void Function(Message message)?;

class ReplyWidget extends ConsumerWidget {
  final Message message;
  final bool alwaysShow;
  final Room room;
  final MessageGroupStatus? groupStatus;
  final OnTapReply onTapReply;
  const ReplyWidget(
    this.message, {
    required this.room,
    required this.groupStatus,
    this.onTapReply,
    this.alwaysShow = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      message.replyToMessageId == null
      ? SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Quoted(
            ref
                .watch(
                  EventController.provider(
                    GetEventRequest(
                      room: room,
                      eventId: message.replyToMessageId!,
                    ),
                  ),
                )
                .betterWhen(
                  loading: () => Text("Fetching event..."),
                  data: (event) => event == null
                      ? SizedBox.shrink()
                      : ref
                            .watch(
                              MessageController.provider(
                                MessageConfig(room: room, event: event),
                              ),
                            )
                            .betterWhen(
                              loading: () => Text("Parsing message..."),
                              data: (replyMessage) {
                                if (replyMessage == null) {
                                  return SizedBox.shrink();
                                }

                                final smallerText =
                                    message is TextMessage &&
                                        replyMessage.metadata?["body"] != null
                                    ? replyMessage.metadata!["body"].substring(
                                        0,
                                        min(
                                          max(
                                            max(
                                              (message as TextMessage)
                                                      .text
                                                      .length -
                                                  (replyMessage
                                                              .metadata?["displayName"]
                                                          as String)
                                                      .length -
                                                  5,
                                              message
                                                  .metadata?["displayName"]
                                                  .length,
                                            ),
                                            5,
                                          ),
                                          replyMessage.metadata!["body"].length,
                                        ),
                                      )
                                    : null;
                                final replyText =
                                    (smallerText == null ||
                                        smallerText.length ==
                                            replyMessage
                                                .metadata!["body"]
                                                .length)
                                    ? replyMessage.metadata!["body"]
                                    : "$smallerText...";

                                return InkWell(
                                  onTap: () => onTapReply?.call(replyMessage),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 8,
                                    children: [
                                      AvatarOrHash(
                                        Uri.tryParse(
                                          replyMessage.metadata?["avatarUrl"] ??
                                              "",
                                        ),
                                        replyMessage.metadata?["displayName"] ??
                                            "",
                                        height: 16,
                                      ),
                                      Flexible(
                                        child: Text(
                                          replyMessage
                                                  .metadata?["displayName"] ??
                                              replyMessage.authorId,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          replyText,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
          ),
        );
}
