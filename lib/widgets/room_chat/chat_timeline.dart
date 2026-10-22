import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const ChatTimeline({
  required final ChatParams chat,
  required final ChatScroll scroll,
  required final JumpToEvent jumpToEvent,
  required final IList<PopupMenuEntry> Function(Event) getEventOptions,
  required final int? highlightedEvent,
  required final double composerHeight,

  /// The typing indicator's height, or zero while it's hidden.
  required final double typingIndicatorHeight,
  final void Function(int rowId)? onSwipe,
  super.key,
}) extends StatelessWidget {
  Widget eventRow(
    int eventRowId,
    int? previousEventRowId, {
    required Key key,
  }) => HighlightWrapper(
    EventRenderer(
      eventRowId,
      previousEventRowId: previousEventRowId,
      roomId: chat.roomId,
      jumpToEvent: jumpToEvent,
      getEventOptions: getEventOptions,
      onSwipe: onSwipe == null ? null : () => onSwipe!(eventRowId),
      readReceiptsChat: chat,
    ),
    key: key,
    isHighlighted: highlightedEvent == eventRowId,
  );

  @override
  Widget build(BuildContext context) => CustomScrollView(
    reverse: true,
    center: scroll.centerKey,
    keyboardDismissBehavior: .onDrag,
    controller: scroll.scrollController,
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          children: [
            // Makes room for the typing indicator, with a small gap above it,
            // so it doesn't cover messages
            AnimatedContainer(
              duration: Durations.medium2,
              curve: Curves.easeInOutCubicEmphasized,
              height: typingIndicatorHeight == 0
                  ? 0
                  : typingIndicatorHeight + 4,
            ),
            SizedBox(height: composerHeight),
          ],
        ),
      ),

      SuperSliverList.builder(
        itemCount: scroll.liveRows.length,
        itemBuilder: (_, index) => eventRow(
          scroll.liveRows[index],
          index > 0
              ? scroll.liveRows.getOrNull(index - 1)
              : scroll.historyRows.firstOrNull,
          key: scroll.keyFor(scroll.liveRows[index]),
        ),
      ),

      SuperSliverList.builder(
        key: scroll.centerKey,
        itemCount: scroll.historyRows.length,
        itemBuilder: (_, index) => eventRow(
          scroll.historyRows[index],
          scroll.historyRows.getOrNull(index + 1),
          key: scroll.keyFor(scroll.historyRows[index]),
        ),
      ),
    ],
  );
}
