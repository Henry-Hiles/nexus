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
  required final Future<void> Function(String id) jumpToId,
}) {
  static ChatScroll<T> use<T>({
    required AsyncValue<IList<T>?> controllerData,
    required String Function(T item) id,
    required Future<void> Function() loadOlder,
    required Future<void> Function() onReachedBottom,
  }) {
    final historyListController = useRef(ListController());
    final liveListController = useRef(ListController());
    final scrollController = useScrollController();
    final centerKey = useMemoized(GlobalKey.new);

    final anchorId = useState<String?>(null);

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

    useEffect(() {
      const topThreshold = 500.0;
      const bottomThreshold = 50.0;

      Future<void> checkPosition() async {
        if (!scrollController.hasClients) return;

        final position = scrollController.position;

        if (position.extentAfter <= topThreshold) {
          await loadOlder();
        } else if (position.extentBefore <= bottomThreshold) {
          await onReachedBottom();
        }
      }

      scrollController.addListener(checkPosition);

      WidgetsBinding.instance.addPostFrameCallback((_) => checkPosition());

      return () {
        scrollController.removeListener(checkPosition);
      };
    }, [scrollController, controllerData, loadOlder, onReachedBottom]);

    Future<void> jumpToId(String itemId) async {
      if (!scrollController.hasClients) return;

      final historyIndex = split.history.indexWhere(
        (item) => id(item) == itemId,
      );

      if (historyIndex != -1) {
        // TODO: Replace SuperSliverView because of the bug that requires this: #94
        // ignore: invalid_use_of_visible_for_testing_member
        final offset = historyListController.value.getOffsetToReveal(
          historyIndex,
          0.5,
        );

        await scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        final liveIndex = split.live.indexWhere((item) => id(item) == itemId);

        if (liveIndex != -1) {
          // ignore: invalid_use_of_visible_for_testing_member
          final offset = liveListController.value.getOffsetToReveal(
            liveIndex,
            0.5,
          );

          await scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      }
    }

    return .new(
      historyItems: split.history,
      liveItems: split.live,
      centerKey: centerKey,
      historyListController: historyListController.value,
      liveListController: liveListController.value,
      scrollController: scrollController,
      jumpToId: jumpToId,
    );
  }
}
