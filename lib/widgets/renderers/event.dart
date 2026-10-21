import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/gestures.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/show_adaptive_menu.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/canonical_alias.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/encrypted.dart";
import "package:nexus/models/content/history_visibility.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/pinned_events.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/content/server_acl.dart";
import "package:nexus/models/content/sticker.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/message.dart";
import "package:nexus/widgets/reaction_row.dart";
import "package:nexus/widgets/renderers/membership.dart";
import "package:nexus/widgets/renderers/generic_event.dart";
import "package:nexus/widgets/swipe_to_reply.dart";
import "package:nexus/widgets/timestamp.dart";

class const EventRenderer(
  final int eventRowId, {
  required final String roomId,
  final int? previousEventRowId,
  final bool textOnly = false,
  final int? maxLines,
  final JumpToEvent? jumpToEvent,
  final IList<PopupMenuEntry> Function(Event event)? getEventOptions,

  /// If set, events can be swiped, calling this
  final VoidCallback? onSwipe,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorStyle = TextStyle(color: colorScheme.error);
    final focusNode = useFocusNode();
    useListenable(focusNode);

    final (event, previousEvent) = ref.watch(
      RoomsController.provider.select((rooms) {
        final event = rooms[roomId]?.events[eventRowId];
        if (event == null) return (null, null);

        final edited = event.lastEditRowId == 0
            ? null
            : rooms[roomId]?.events[event.lastEditRowId];

        return (
          edited == null
              ? event
              : event.copyWith(
                  content: edited.content,
                  localContent: edited.localContent,
                ),
          previousEventRowId == null
              ? null
              : rooms[roomId]?.events[previousEventRowId!],
        );
      }),
    );

    if (event == null) return SizedBox.shrink();

    final hideMembershipEvents = (ref
        .watch(SettingsController.provider)
        .maybeWhen(
          orElse: () => false,
          data: (settings) => settings.hideMembershipEvents,
        ));

    // Knocks and their outcomes stay visible, as moderators need to act on them
    if (hideMembershipEvents &&
        event.content is MembershipContent &&
        ![event.content, event.previousContent].any(
          (content) => content is MembershipContent && content.status == .knock,
        )) {
      return SizedBox.shrink();
    }

    final isGrouped =
        previousEvent?.content is MessageContent &&
        previousEvent?.redactedBy == null &&
        previousEvent?.relationType != "m.replace" &&
        event.sender == previousEvent?.sender &&
        event.pmp?.id == previousEvent?.pmp?.id;

    GenericEventRenderer generic(IconData icon, String text) =>
        .new(icon, maxLines: maxLines, [
          WidgetSpan(
            alignment: .middle,
            child: MessageDisplayname(event, shouldWrap: maxLines == null),
          ),
          TextSpan(text: text),
        ]);

    final child = event.redactedBy != null || event.relationType == "m.replace"
        ? null
        : switch (event.content) {
            Content(:final parseError?, :final stackTrace) => Row(
              children: [
                ErrorDialog(
                  "An error occurred while parsing event ${event.eventId}:\n$parseError",
                  stackTrace,
                ),
              ],
            ),

            MessageContent() ||
            EncryptedContent() ||
            StickerContent() => MessageRenderer(
              event,
              onTapReply: jumpToEvent == null
                  ? null
                  : () async {
                      final replyEvent = await ref.read(
                        EventController.provider(
                          .new(roomId: roomId, eventId: event.replyTo!),
                        ).future,
                      );
                      if (replyEvent != null) {
                        await jumpToEvent!(replyEvent.rowId);
                      }
                    },
              isGrouped: isGrouped,
              maxLines: maxLines,
              textOnly: textOnly,
            ),

            MembershipContent content => switch (event.previousContent) {
              MembershipContent(:final status) =>
                status == content.status
                    ? null
                    : MembershipRenderer(event, maxLines: maxLines),
              _ => MembershipRenderer(event, maxLines: maxLines),
            },

            AvatarContent() => generic(
              Icons.interests,
              "changed the room avatar",
            ),
            CreateContent() => generic(Icons.add, "created the room"),
            PowerLevelsContent() => generic(
              Icons.power,
              "changed the room's power levels",
            ),
            JoinRulesContent() => generic(
              Icons.rule,
              "changed the room's join rules",
            ),
            TopicContent() => generic(
              Icons.description,
              "updated the room topic",
            ),
            HistoryVisibilityContent(:final historyVisibility) => generic(
              Icons.history,
              "changed the room's history visibility to ${switch (historyVisibility) {
                .invited => "since invited",
                .joined => "since joined",
                .shared => "all history visible (shared)",
                .worldReadable => "all history visible (world readable)",
              }}",
            ),
            PinnedEventsContent() => generic(
              Icons.push_pin,
              "pinned/unpinned some events",
            ),
            ServerACLContent() => generic(
              Icons.list,
              "updated the server ban list",
            ),
            CanonicalAliasContent(:final alias, :final altAliases) => generic(
              Icons.numbers,
              switch ([
                if (event.previousContent case CanonicalAliasContent(
                  alias: final prevAlias,
                  altAliases: final prevAltAliases,
                )) ...[
                  if (prevAlias != alias)
                    if (alias == null)
                      "removed the room's canonical alias"
                    else
                      "changed the room's canonical alias to $alias",

                  if (prevAltAliases
                          .remove(alias ?? "")
                          .remove(prevAlias ?? "") !=
                      altAliases.remove(alias ?? "").remove(prevAlias ?? ""))
                    "changed the room's aliases",
                ] else ...[
                  if (alias != null) "set the room's canonical alias",
                  if (altAliases.isNotEmpty) "set the room's aliases",
                ],
              ]) {
                [] => "did something related to room aliases",
                List prev => prev.join(" and "),
              },
            ),
            _ => null,
          };

    final contextMenuCallback = getEventOptions == null
        ? null
        : (PositionedGestureDetails details) => context.showAdaptiveMenu(
            getEventOptions!(event).toList(),
            globalPosition: details.globalPosition,
          );

    return Column(
      crossAxisAlignment: .start,
      children: [
        if (child != null)
          if (textOnly)
            child
          else ...[
            Builder(
              builder: (context) => FocusableActionDetector(
                focusNode: focusNode,
                actions: contextMenuCallback == null
                    ? null
                    : {
                        ActivateIntent: CallbackAction(
                          onInvoke: (_) {
                            final renderBox =
                                context.findRenderObject() as RenderBox;
                            final topLeft = renderBox.localToGlobal(
                              Offset.zero,
                            );
                            context.showAdaptiveMenu(
                              getEventOptions!(event).toList(),
                              globalPosition: topLeft,
                            );
                            return null;
                          },
                        ),
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: focusNode.hasPrimaryFocus
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                  ),
                  child: GestureDetector(
                    onSecondaryTapUp: contextMenuCallback,
                    onLongPressStart: contextMenuCallback,
                    child: SwipeToReply(
                      onSwipe: onSwipe,
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8)
                            .copyWith(top: isGrouped ? 0 : 8),
                        child: Wrap(
                          verticalDirection: .up,
                          spacing: 6,
                          crossAxisAlignment: .center,
                          children: [
                            child,
                            if (child is! MessageRenderer)
                              Timestamp(event.timestamp),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            ...[
              if (child is! MessageRenderer) ReactionRow(event),

              if (event.sendError != null && event.sendError != "not sent")
                Padding(
                  padding: .only(bottom: 4),
                  child: Row(
                    spacing: 4,
                    children: [
                      Text(
                        event.sendError!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      InkWell(
                        child: Text(
                          "Hide",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: .underline,
                            decorationColor: theme.colorScheme.primary,
                          ),
                        ),
                        onTap: () => ref
                            .read(
                              RoomChatController.provider((
                                roomId: roomId,
                                contextualEvent: null,
                              )).notifier,
                            )
                            .hideClientSticky(event.rowId),
                      ),
                    ],
                  ),
                ),
            ].map((child) => Padding(padding: .only(left: 4), child: child)),
          ]
        else if (textOnly)
          Text("Unknown event type", style: errorStyle),
      ],
    );
  }
}
