import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/gestures.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/event.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/is_shown_as_message.dart";
import "package:nexus/helpers/extensions/show_adaptive_menu.dart";
import "package:nexus/helpers/extensions/success_scheme.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/helpers/hooks/tap_recognizer.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/canonical_alias.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/encryption.dart";
import "package:nexus/models/content/history_visibility.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/pinned_events.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/content/server_acl.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/renderers/message.dart";
import "package:nexus/widgets/reaction_row.dart";
import "package:nexus/widgets/read_receipts_row.dart";
import "package:nexus/widgets/renderers/membership.dart";
import "package:nexus/widgets/renderers/change_line.dart";
import "package:nexus/widgets/renderers/generic_event.dart";
import "package:nexus/widgets/renderers/join_rules_diff.dart";
import "package:nexus/widgets/renderers/power_levels_diff.dart";
import "package:nexus/widgets/renderers/pinned_events_diff.dart";
import "package:nexus/widgets/renderers/server_acl_diff.dart";
import "package:nexus/widgets/swipe_to_reply.dart";
import "package:nexus/widgets/timestamp.dart";
import "package:nexus/widgets/user_span.dart";

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

  /// If set, shows who in this chat has read up to this event, e.g. in the
  /// timeline.
  final ChatParams? readReceiptsChat,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorStyle = TextStyle(color: colorScheme.error);
    final focusNode = useFocusNode();
    useListenable(focusNode);
    final senderRecognizer = useTapRecognizer();

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

    final (hideMembershipEvents, hideServerAclEvents) = ref
        .watch(SettingsController.provider)
        .maybeWhen(
          orElse: () => (false, true),
          data: (settings) =>
              (settings.hideMembershipEvents, settings.hideServerAclEvents),
        );

    // Knocks and their outcomes stay visible, as moderators need to act on them
    if (hideMembershipEvents &&
        event.content is MembershipContent &&
        ![event.content, event.previousContent].any(
          (content) => content is MembershipContent && content.status == .knock,
        )) {
      return SizedBox.shrink();
    }

    if (hideServerAclEvents && event.content is ServerACLContent) {
      return SizedBox.shrink();
    }

    final isGrouped =
        (previousEvent?.isShownAsMessage ?? false) &&
        event.sender == previousEvent?.sender &&
        event.pmp?.id == previousEvent?.pmp?.id;

    // For what a state event changed, from and to
    final removedColor = colorScheme.error;
    final addedColor = theme.successScheme.primary;

    GenericEventRenderer generic(
      IconData icon,
      String text, {
      List<Widget> details = const [],
    }) => .new(
      icon,
      maxLines: maxLines,
      details: details,
      trailing: Timestamp(event.timestamp),
      [
        UserSpan.sender(context, ref, event, recognizer: senderRecognizer),
        TextSpan(text: text),
      ],
    );

    final child = event.isShownAsMessage
        ? MessageRenderer(
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
          )
        : event.redactedBy != null || event.relationType == "m.replace"
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
            final PowerLevelsContent content => generic(
              Icons.power,
              "changed the room's power levels",
              details: [
                PowerLevelsDiff(
                  roomId,
                  content,
                  previous: switch (event.previousContent) {
                    final PowerLevelsContent previous => previous,
                    _ => null,
                  },
                ),
              ],
            ),
            final JoinRulesContent content => generic(
              Icons.rule,
              "changed the room's join rules",
              details: [
                JoinRulesDiff(
                  content,
                  previous: switch (event.previousContent) {
                    final JoinRulesContent previous => previous,
                    _ => null,
                  },
                ),
              ],
            ),
            TopicContent(:final topic) => () {
              final previous = switch (event.previousContent) {
                TopicContent(:final topic) when topic.isNotEmpty => topic,
                _ => null,
              };

              return generic(
                Icons.description,
                topic.isEmpty
                    ? "removed the room topic"
                    : previous == null
                    ? "set the room topic"
                    : "changed the room topic",
                details: [
                  ChangeLine(
                    removed: [?previous].lock,
                    added: [if (topic.isNotEmpty) topic].lock,
                    removedColor: removedColor,
                    addedColor: addedColor,
                    quoted: false,
                  ),
                ],
              );
            }(),
            HistoryVisibilityContent(:final historyVisibility) => generic(
              Icons.history,
              "changed the room's history visibility to ${switch (historyVisibility) {
                .invited => "since invited",
                .joined => "since joined",
                .shared => "all history visible (shared)",
                .worldReadable => "all history visible (world readable)",
                .unknown => "something Nexus doesn't know about",
              }}",
            ),
            PinnedEventsContent(:final pinnedEvents) => () {
              final before = switch (event.previousContent) {
                PinnedEventsContent(:final pinnedEvents) => pinnedEvents,
                _ => const IList<String>.empty(),
              };
              final pinned = pinnedEvents
                  .where((id) => !before.contains(id))
                  .toIList();
              final unpinned = before
                  .where((id) => !pinnedEvents.contains(id))
                  .toIList();

              return generic(
                Icons.push_pin,
                switch ((pinned.length, unpinned.length)) {
                  (1, 0) => "pinned a message",
                  (0, 1) => "unpinned a message",
                  _ => "changed the pinned messages",
                },
                details: [
                  PinnedEventsDiff(
                    roomId,
                    pinned: pinned,
                    unpinned: unpinned,
                    jumpToEvent: jumpToEvent,
                  ),
                ],
              );
            }(),
            final ServerACLContent content => generic(
              Icons.list,
              "updated the server ban list",
              details: [
                ServerAclDiff(
                  content,
                  previous: switch (event.previousContent) {
                    final ServerACLContent previous => previous,
                    _ => null,
                  },
                ),
              ],
            ),
            CanonicalAliasContent(:final alias, :final altAliases) => () {
              final previous = switch (event.previousContent) {
                final CanonicalAliasContent previous => previous,
                _ => null,
              };
              final previousAltAliases =
                  previous?.altAliases ?? const ISet<String>.empty();

              return generic(
                Icons.numbers,
                previous == null
                    ? "set the room's aliases"
                    : "changed the room's aliases",
                details: [
                  if (previous?.alias != alias)
                    ChangeLine(
                      label: "Canonical alias",
                      removed: [?previous?.alias].lock,
                      added: [?alias].lock,
                      removedColor: removedColor,
                      addedColor: addedColor,
                    ),
                  if (previousAltAliases != altAliases)
                    ChangeLine(
                      label: "Aliases",
                      removed: previousAltAliases
                          .difference(altAliases)
                          .toIList(),
                      added: altAliases
                          .difference(previousAltAliases)
                          .toIList(),
                      removedColor: removedColor,
                      addedColor: addedColor,
                    ),
                ],
              );
            }(),
            NameContent(:final name) => () {
              final previous = switch (event.previousContent) {
                NameContent(:final name) when name.isNotEmpty => name,
                _ => null,
              };

              return generic(
                Icons.title,
                name.isEmpty
                    ? "removed the room name"
                    : previous == null
                    ? "set the room name"
                    : "changed the room name",
                details: [
                  ChangeLine(
                    removed: [?previous].lock,
                    added: [if (name.isNotEmpty) name].lock,
                    removedColor: removedColor,
                    addedColor: addedColor,
                  ),
                ],
              );
            }(),
            EncryptionContent() => generic(
              Icons.lock,
              event.previousContent is EncryptionContent
                  ? "changed the room's encryption settings"
                  : "enabled encryption",
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
                            if (child is! MessageRenderer &&
                                child is! GenericEventRenderer)
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

              // Outside the message itself, so it doesn't move when swiped
              if (readReceiptsChat case final chat? when event.isShownAsMessage)
                ReadReceiptsRow(event.eventId, chat: chat),

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
