import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:super_sliver_list/super_sliver_list.dart";

final class ChatScroll<T>({
  required final IList<T> historyItems,
  required final IList<T> liveItems,
  required final GlobalKey centerKey,
  required final ListController historyListController,
  required final ListController liveListController,
  required final ScrollController scrollController,
  required final bool hasMore,
  required final bool isLoadingOlder,
  required final Future<void> Function() loadOlder,
  required final Future<void> Function(String id) jumpToId,
}) {
  static ChatScroll<T> use<T>({
    required AsyncValue<IList<T>?> controllerData,
    required String Function(T item) id,
    required Future<bool> Function() loadOlder,
    required Future<void> Function() onReachedBottom,
  }) {
    final historyListController = useRef(ListController());
    final liveListController = useRef(ListController());
    final scrollController = useScrollController();
    final centerKey = useMemoized(GlobalKey.new);

    final anchorId = useState<String?>(null);
    final hasMore = useState(true);
    final isLoadingOlder = useState(false);

    final anchorIdValue = anchorId.value;

    useEffect(() {
      if (anchorId.value == null) {
        if (controllerData case AsyncData(:final value?)
            when value.isNotEmpty) {
          anchorId.value = id(value.last);
        }
      }

      return null;
    }, [controllerData]);

    final ({IList<T> history, IList<T> live}) split = useMemoized(() {
      final items = controllerData.value;
      final anchor = anchorIdValue;

      if (items == null || anchor == null) {
        return (history: const .empty(), live: const .empty());
      }

      final anchorIndex = items.indexWhere((item) => id(item) == anchor);

      if (anchorIndex == -1) {
        return (history: const .empty(), live: items);
      }

      return (
        history: items.take(anchorIndex).toIList().reversed.toIList(),
        live: items.skip(anchorIndex).toIList(),
      );
    }, [controllerData, anchorIdValue]);

    Future<void> loadOlderItems() async {
      if (!hasMore.value || isLoadingOlder.value) return;

      isLoadingOlder.value = true;

      try {
        hasMore.value = await loadOlder();
      } finally {
        isLoadingOlder.value = false;
      }
    }

    Future<void> jumpToId(String itemId) async {
      if (!scrollController.hasClients) return;

      final historyIndex = split.history.indexWhere(
        (item) => id(item) == itemId,
      );

      if (historyIndex != -1) {
        historyListController.value.animateToItem(
          index: historyIndex,
          scrollController: scrollController,
          alignment: 0.5,
          duration: (_) => .new(milliseconds: 700),
          curve: (_) => Curves.easeInOut,
        );

        return;
      }

      final liveIndex = split.live.indexWhere((item) => id(item) == itemId);

      if (liveIndex != -1) {
        liveListController.value.animateToItem(
          index: liveIndex,
          scrollController: scrollController,
          alignment: 0.5,
          duration: (_) => .new(milliseconds: 700),
          curve: (_) => Curves.easeInOut,
        );
      }
    }

    useEffect(() {
      const loadThreshold = 500.0;
      const bottomThreshold = 50.0;

      void checkPosition() {
        if (!scrollController.hasClients) {
          return;
        }

        final position = scrollController.position;

        if (position.extentAfter <= loadThreshold) {
          if (hasMore.value && !isLoadingOlder.value) {
            loadOlderItems();
          }
        }

        if (position.extentBefore <= bottomThreshold) {
          onReachedBottom();
        }
      }

      scrollController.addListener(checkPosition);

      WidgetsBinding.instance.addPostFrameCallback((_) => checkPosition());

      return () => scrollController.removeListener(checkPosition);
    }, [scrollController, onReachedBottom]);

    return .new(
      historyItems: split.history,
      liveItems: split.live,
      centerKey: centerKey,
      historyListController: historyListController.value,
      liveListController: liveListController.value,
      scrollController: scrollController,
      hasMore: hasMore.value,
      isLoadingOlder: isLoadingOlder.value,
      loadOlder: loadOlderItems,
      jumpToId: jumpToId,
    );
  }
}
