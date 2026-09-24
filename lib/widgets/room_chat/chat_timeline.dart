import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const ChatTimeline({
  required final AsyncValue<IList<Event>?> controllerData,
  required final ScrollController scrollController,
  required final ListController listController,
  required final bool hasMore,
  required final Future<void> Function() loadOlder,
  required final Future<void> Function(String) jumpToId,
  required final IList<PopupMenuEntry> Function(Event) getEventOptions,
  required final String? highlightedEvent,
  required final double composerHeight,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (controllerData) {
    AsyncData(:final value?) || AsyncLoading(:final value?) => CustomScrollView(
      keyboardDismissBehavior: .onDrag,
      controller: scrollController,
      slivers: [
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: .symmetric(vertical: 36),
              child: Center(
                child: ElevatedButton(
                  onPressed: controllerData is AsyncData ? loadOlder : null,
                  child: Text("Load More"),
                ),
              ),
            ),
          ),

        SuperSliverList.builder(
          listController: listController,
          itemCount: value.length,
          itemBuilder: (_, index) {
            final event = value[index];
            final previousEvent = value.getOrNull(index - 1);
            return HighlightWrapper(
              EventRenderer(
                event,
                onTapReply: () => jumpToId(event.replyTo!),
                getEventOptions: getEventOptions,
                isGrouped:
                    previousEvent?.content is MessageContent &&
                    previousEvent?.redactedBy == null &&
                    previousEvent?.relationType != "m.replace" &&
                    event.sender == previousEvent?.sender &&
                    event.pmp?.id == previousEvent?.pmp?.id,
              ),
              isHighlighted: highlightedEvent == event.eventId,
            );
          },
        ),

        SliverPadding(padding: .only(bottom: composerHeight)),
      ],
    ),
    AsyncData() => Center(child: Text("Nothing to see here...")),
    AsyncLoading() => Loading(),
    AsyncError(:final error, :final stackTrace) => ErrorDialog(
      error,
      stackTrace,
    ),
  };
}
