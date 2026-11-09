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
  required final double composerHeight,

  /// The typing indicator's height, or zero while it's hidden.
  required final double typingIndicatorHeight,
  final void Function(int rowId)? onSwipe,
  final void Function(String threadRoot)? onOpenThread,
  super.key,
}) extends StatelessWidget {
  Widget eventRow(
    int eventRowId,
    int? previousEventRowId, {
    required Key key,
  }) => HighlightWrapper(
    // To work around an AWFUL SuperSliverList bug
    ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 0.01),
      child: EventRenderer(
        eventRowId,
        previousEventRowId: previousEventRowId,
        roomId: chat.roomId,
        jumpToEvent: jumpToEvent,
        onOpenThread: onOpenThread,
        getEventOptions: getEventOptions,
        onSwipe: onSwipe == null ? null : () => onSwipe!(eventRowId),
        readReceiptsChat: chat,
        threadRoot: chat.threadRoot,
      ),
    ),
    key: key,
    isHighlighted: scroll.highlightedEvent == eventRowId,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => TweenAnimationBuilder(
      // Makes room for the typing indicator, with a small gap above it, so it
      // doesn't cover messages
      tween: Tween(
        end: typingIndicatorHeight == 0 ? 0.0 : typingIndicatorHeight + 4,
      ),
      duration: Durations.medium2,
      curve: Curves.easeInOutCubicEmphasized,
      builder: (context, typingIndicatorGap, _) {
        final bottomPadding = composerHeight + typingIndicatorGap;

        return CustomScrollView(
          reverse: true,
          center: scroll.centerKey,
          // Offset 0 is the newest event above the padding, so short
          // timelines can't be scrolled past either end
          anchor: (bottomPadding / constraints.maxHeight).clamp(0, 1),
          keyboardDismissBehavior: .onDrag,
          controller: scroll.scrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),

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
      },
    ),
  );
}
