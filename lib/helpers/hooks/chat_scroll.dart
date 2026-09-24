import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:super_sliver_list/super_sliver_list.dart";

final class ChatScroll({
  required final ListController listController,
  required final ScrollController scrollController,
  required final bool hasMore,
  required final Future<void> Function() loadOlder,
  required final Future<void> Function(String id) jumpToId,
}) {
  static ChatScroll use<T>({
    required AsyncValue<IList<T>?> controllerData,
    required String Function(T item) id,
    required Future<bool> Function() loadOlder,
    required bool Function() shouldLoadOlder,
    required Future<void> Function() onReachedBottom,
  }) {
    final listController = useRef(ListController());
    final scrollController = useScrollController();

    final hasMore = useState(true);
    final topItemBeforeLoad = useState<String?>(null);
    final loadingOlder = useRef(false);
    final initialized = useRef(false);

    Future<void> loadOlderItems() async {
      if (loadingOlder.value || !hasMore.value) return;

      if (controllerData case AsyncData(:final value?)) {
        loadingOlder.value = true;
        topItemBeforeLoad.value = value.firstOrNull == null
            ? null
            : id(value.first);

        try {
          hasMore.value = await loadOlder();
        } finally {
          loadingOlder.value = false;
        }
      }
    }

    Future<void> jumpToId(String itemId) async {
      final index =
          controllerData.value?.indexWhere((item) => id(item) == itemId) ?? -1;

      if (index == -1) return;

      listController.value.animateToItem(
        index: index,
        scrollController: scrollController,
        alignment: 0.5,
        duration: (_) => .new(milliseconds: 700),
        curve: (_) => Curves.easeInOut,
      );
    }

    useEffect(() {
      if (controllerData case AsyncData(:final value?)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients) return;

          if (!initialized.value) {
            initialized.value = true;

            if (value.isNotEmpty) {
              listController.value.jumpToItem(
                index: value.length - 1,
                scrollController: scrollController,
                alignment: 1,
              );
            }
            return;
          }

          final topItem = topItemBeforeLoad.value;

          if (topItem != null) {
            final index = value.indexWhere((item) => id(item) == topItem);

            if (index != -1) {
              listController.value.jumpToItem(
                index: index,
                scrollController: scrollController,
                alignment: 0,
              );
            }

            topItemBeforeLoad.value = null;
          } else if (scrollController.position.atEdge &&
              scrollController.position.pixels != 0) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });
      }

      return null;
    }, [controllerData]);

    useEffect(() {
      Future<void> listener() async {
        if (!scrollController.hasClients || !scrollController.position.atEdge) {
          return;
        }

        if (scrollController.position.pixels == 0) {
          if (shouldLoadOlder()) {
            await loadOlderItems();
          }
        } else {
          await onReachedBottom();
        }
      }

      scrollController.addListener(listener);

      return () => scrollController.removeListener(listener);
    }, [controllerData]);

    return .new(
      listController: listController.value,
      scrollController: scrollController,
      hasMore: hasMore.value,
      loadOlder: loadOlderItems,
      jumpToId: jumpToId,
    );
  }
}
