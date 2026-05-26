import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/extensions/show_context_menu.dart";
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
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/lazy_loading/message_displayname.dart";
import "package:nexus/widgets/renderers/message.dart";
import "package:nexus/widgets/reaction_row.dart";
import "package:nexus/widgets/renderers/membership.dart";
import "package:nexus/widgets/renderers/generic_event.dart";

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

    final child = event.redactedBy != null || event.relationType == "m.replace"
        ? null
        : switch (event.content) {
            Content(:final parseError?) => SelectableText(
              "An error occurred while parsing this event:\n$parseError\n${parseError.stackTrace}",
              style: errorStyle,
            ),

            MessageContent() || EncryptedContent() => MessageRenderer(
              event,
              onTapReply: onTapReply,
              isGrouped: isGrouped,
              maxLines: maxLines,
              textOnly: textOnly,
            ),

            MembershipContent content =>
              event.previousContent is MembershipContent &&
                      (event.previousContent as MembershipContent).status ==
                          content.status
                  ? null
                  : MembershipRenderer(event),

            AvatarContent() => GenericEventRenderer(Icons.interests, [
              MessageDisplayname(event),
              Text("changed the room avatar"),
            ]),

            CreateContent() => GenericEventRenderer(Icons.add, [
              MessageDisplayname(event),
              Text("created the room"),
            ]),

            PowerLevelsContent() => GenericEventRenderer(Icons.add, [
              MessageDisplayname(event),
              Text("changed the room's power levels"),
            ]),

            JoinRulesContent() => GenericEventRenderer(Icons.add, [
              MessageDisplayname(event),
              Text("changed the room's join rules"),
            ]),

            TopicContent() => GenericEventRenderer(Icons.description, [
              MessageDisplayname(event),
              Text("updated the room topic"),
            ]),

            HistoryVisibilityContent(:final historyVisibility) =>
              GenericEventRenderer(Icons.history, [
                MessageDisplayname(event),
                Text(
                  "changed the room's history visibility to ${switch (historyVisibility) {
                    HistoryVisibility.invited => "since invited",
                    HistoryVisibility.joined => "since joined",
                    HistoryVisibility.shared => "all history visible (shared)",
                    HistoryVisibility.worldReadable => "all history visible (world readable)",
                  }}",
                ),
              ]),

            PinnedEventsContent() => GenericEventRenderer(Icons.push_pin, [
              MessageDisplayname(event),
              Text("pinned/unpinned some events"),
            ]),

            ServerACLContent() => GenericEventRenderer(Icons.list, [
              MessageDisplayname(event),
              Text("updated the server ban list"),
            ]),

            CanonicalAliasContent(:final alias, :final altAliases) =>
              GenericEventRenderer(Icons.numbers, [
                MessageDisplayname(event),
                Text(switch ([
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
                }),
              ]),
            _ => null,
          };

    final contextMenuCallback = getEventOptions == null
        ? null
        : (details) => context.showContextMenu(
            globalPosition: details.globalPosition,
            children: getEventOptions!(event).toList(),
          );

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

          ...[
            if (event.content is! MessageContent) ReactionRow(event),

            if (event.sendError != null && event.sendError != "not sent")
              Text(
                event.sendError!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ].map(
            (child) => Padding(
              padding: EdgeInsetsGeometry.only(left: 4),
              child: child,
            ),
          ),
        ] else if (textOnly)
          Text("Unknown event type", style: errorStyle),
      ],
    );
  }
}
