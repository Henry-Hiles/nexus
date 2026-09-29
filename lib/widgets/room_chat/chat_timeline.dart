import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const ChatTimeline({
  required final String roomId,
  required final ChatScroll scroll,
  required final JumpToEvent jumpToEvent,
  required final IList<PopupMenuEntry> Function(Event) getEventOptions,
  required final int? highlightedEvent,
  required final double composerHeight,
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
      roomId: roomId,
      jumpToEvent: jumpToEvent,
      getEventOptions: getEventOptions,
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
      SliverToBoxAdapter(child: SizedBox(height: composerHeight)),

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
