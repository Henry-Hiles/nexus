import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const ChatTimeline({
  required final ChatScroll scroll,
  required final Future<void> Function(String) jumpToId,
  required final IList<PopupMenuEntry> Function(Event) getEventOptions,
  required final String? highlightedEvent,
  required final double composerHeight,
  super.key,
}) extends StatelessWidget {
  bool isGrouped(Event event, Event? previousEvent) =>
      previousEvent?.content is MessageContent &&
      previousEvent?.redactedBy == null &&
      previousEvent?.relationType != "m.replace" &&
      event.sender == previousEvent?.sender &&
      event.pmp?.id == previousEvent?.pmp?.id;

  Widget eventRow(
    Event event,
    Event? previousEvent, {
    required Future<void> Function(String) jumpToId,
    required IList<PopupMenuEntry> Function(Event) getEventOptions,
    required String? highlightedEvent,
    required Key key,
  }) => HighlightWrapper(
    EventRenderer(
      event,
      onTapReply: () => jumpToId(event.replyTo!),
      getEventOptions: getEventOptions,
      isGrouped: isGrouped(event, previousEvent),
    ),
    key: key,
    isHighlighted: highlightedEvent == event.eventId,
  );

  @override
  Widget build(BuildContext context) => CustomScrollView(
    reverse: true,
    center: scroll.centerKey,
    keyboardDismissBehavior: .onDrag,
    controller: scroll.scrollController,
    slivers: [
      SliverToBoxAdapter(child: SizedBox(height: composerHeight)),

      SuperSliverList.builder(
        itemCount: scroll.liveItems.length,
        itemBuilder: (_, index) => eventRow(
          scroll.liveItems[index],
          index > 0
              ? scroll.liveItems.getOrNull(index - 1)
              : scroll.historyItems.firstOrNull,
          jumpToId: jumpToId,
          getEventOptions: getEventOptions,
          highlightedEvent: highlightedEvent,
          key: index == 0
              ? scroll.anchorItemKey
              : ValueKey(scroll.liveItems[index].eventId),
        ),
      ),

      SuperSliverList.builder(
        key: scroll.centerKey,
        itemCount: scroll.historyItems.length,
        itemBuilder: (_, index) => eventRow(
          scroll.historyItems[index],
          scroll.historyItems.getOrNull(index + 1),
          jumpToId: jumpToId,
          getEventOptions: getEventOptions,
          highlightedEvent: highlightedEvent,
          key: ValueKey(scroll.historyItems[index].eventId),
        ),
      ),
    ],
  );
}
