import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/direction.dart";
import "package:nexus/models/room_chat.dart";

typedef JumpToEvent = Future<void> Function(int rowId);

final class ChatScroll({
  required final IList<int> historyRows,
  required final IList<int> liveRows,
  required final GlobalKey centerKey,
  required final ScrollController scrollController,
  required final bool atBottom,
  required final JumpToEvent jumpToEvent,
  required final Future<void> Function() jumpToBottom,
  required final GlobalKey Function(int eventRowId) keyFor,
}) {
  factory use({
    required AsyncValue<RoomChat?> controllerData,
    required Future<void> Function(Direction direction) paginate,
    required Future<void> Function() markRead,
    required ValueNotifier<int?> contextualEvent,
  }) {
    final anchorId = useState<int?>(null);
    final atBottom = useState(true);
    final pendingJump = useState<int?>(null);
    final scrollController = useScrollController();
    final centerKey = useMemoized(GlobalKey.new);

    final itemKeys = useMemoized(() => <int, GlobalKey>{}, []);
    GlobalKey keyFor(int eventRowId) =>
        itemKeys.putIfAbsent(eventRowId, GlobalKey.new);

    useEffect(() {
      if (anchorId.value == null) {
        if (controllerData case AsyncData(:final value?)
            when value.timeline.isNotEmpty) {
          anchorId.value = value.timeline.contains(contextualEvent.value)
              ? contextualEvent.value
              : value.timeline.last;
        }
      }

      return null;
    }, [controllerData, contextualEvent.value]);

    useEffect(() {
      final rowId = pendingJump.value;
      if (rowId == null || anchorId.value != rowId) return null;
      pendingJump.value = null;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!scrollController.hasClients) return;

        final position = scrollController.position;
        scrollController.jumpTo(
          (-position.viewportDimension)
              .clamp(position.minScrollExtent, position.maxScrollExtent)
              .toDouble(),
        );
        await WidgetsBinding.instance.endOfFrame;

        final context = keyFor(rowId).currentContext;
        if (context?.mounted == true) {
          await Scrollable.ensureVisible(
            context!,
            alignment: 0.5,
            duration: const .new(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });

      return null;
    }, [anchorId.value, pendingJump.value]);

    final ({IList<int> history, IList<int> live}) split = useMemoized(() {
      final items = controllerData.value?.timeline;
      final anchor = anchorId.value;

      if (items == null || anchor == null) {
        return (history: const .empty(), live: const .empty());
      }

      final anchorIndex = items.indexOf(anchor);

      if (anchorIndex == -1) return (history: const .empty(), live: items);

      return (
        history: items.take(anchorIndex).toIList().reversed.toIList(),
        live: items.skip(anchorIndex).toIList(),
      );
    }, [controllerData, anchorId.value]);

    useEffect(
      () {
        const loadThreshold = 500.0;

        Future<void> checkPosition() async {
          if (!scrollController.hasClients) return;

          final position = scrollController.position;

          final isAtBottom = position.extentBefore <= 0;
          if (isAtBottom != atBottom.value) atBottom.value = isAtBottom;

          if (position.extentAfter <= loadThreshold) {
            await paginate(.backward);
          } else if (contextualEvent.value != null &&
              position.extentBefore <= loadThreshold) {
            await paginate(.forward);
          } else if (position.extentBefore <= 0) {
            await markRead();
          }

          if (controllerData.isLoading == false &&
              position.extentBefore <= 0 &&
              controllerData.value?.hasMoreForward == false &&
              contextualEvent.value != null) {
            anchorId.value = null;
            contextualEvent.value = null;
          }
        }

        scrollController.addListener(checkPosition);
        WidgetsBinding.instance.addPostFrameCallback((_) => checkPosition());

        return () => scrollController.removeListener(checkPosition);
      },
      [
        scrollController,
        controllerData,
        paginate,
        markRead,
        contextualEvent.value,
      ],
    );

    return .new(
      historyRows: split.history,
      liveRows: split.live,
      centerKey: centerKey,
      scrollController: scrollController,
      atBottom: atBottom.value,
      keyFor: keyFor,
      jumpToEvent: (int rowId) async {
        if (!scrollController.hasClients) return;

        final context = keyFor(rowId).currentContext;
        if (context != null) {
          await Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const .new(milliseconds: 700),
            curve: Curves.easeInOut,
          );
          return;
        }

        pendingJump.value = rowId;
        if (controllerData.value?.timeline.contains(rowId) ?? false) {
          anchorId.value = rowId;
        } else {
          anchorId.value = null;
          contextualEvent.value = rowId;
        }
      },
      jumpToBottom: () async {
        if (contextualEvent.value != null) {
          anchorId.value = null;
          contextualEvent.value = null;
        }

        if (!scrollController.hasClients) return;

        await scrollController.animateTo(
          scrollController.position.minScrollExtent,
          duration: const .new(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      },
    );
  }
}
