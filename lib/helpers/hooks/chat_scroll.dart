import "dart:async";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/direction.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room_chat.dart";

final class ChatScroll({
  required final IList<Event> historyItems,
  required final IList<Event> liveItems,
  required final GlobalKey centerKey,
  required final GlobalKey anchorItemKey,
  required final ScrollController scrollController,
  required final bool atBottom,
  required final Future<void> Function(String id) jumpToId,
  required final Future<void> Function() jumpToBottom,
}) {
  factory use({
    required AsyncValue<RoomChat?> controllerData,
    required Future<void> Function(Direction direction) paginate,
    required Future<void> Function() markRead,
    required ValueNotifier<String?> contextualEvent,
  }) {
    final anchorId = useState<String?>(null);

    final anchorItemKey = useMemoized(GlobalKey.new, [anchorId.value]);

    final scrollController = useScrollController();
    final centerKey = useMemoized(GlobalKey.new);

    final atBottom = useState(true);

    final pendingAnchorTarget = useState<String?>(null);
    final anchorMountedCompleter = useRef<Completer<BuildContext>?>(null);

    useEffect(() {
      if (anchorId.value == null) {
        if (controllerData case AsyncData(:final value?)
            when value.timeline.isNotEmpty) {
          final hasContextualEvent = value.timeline.any(
            (event) => event.eventId == contextualEvent.value,
          );

          anchorId.value = hasContextualEvent
              ? contextualEvent.value
              : value.timeline.last.eventId;
        }
      }

      return null;
    }, [controllerData, contextualEvent.value]);

    useEffect(() {
      final target = pendingAnchorTarget.value;
      if (target == null) return null;

      final found =
          controllerData.value?.timeline.any(
            (event) => event.eventId == target,
          ) ??
          false;

      if (found || controllerData is AsyncError) {
        if (found) {
          anchorId.value = target;
        } else {
          anchorMountedCompleter.value?.completeError(
            StateError("Failed to load context for $target"),
          );
          anchorMountedCompleter.value = null;
        }
        pendingAnchorTarget.value = null;
      }

      return null;
    }, [controllerData, pendingAnchorTarget.value]);

    useEffect(() {
      final completer = anchorMountedCompleter.value;
      if (completer == null) return null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = anchorItemKey.currentContext;
        if (context != null && context.mounted) {
          anchorMountedCompleter.value?.complete(context);
          anchorMountedCompleter.value = null;
        }
      });

      return null;
    }, [anchorId.value]);

    final ({IList<Event> history, IList<Event> live}) split = useMemoized(() {
      final items = controllerData.value?.timeline;
      final anchor = anchorId.value;

      if (items == null || anchor == null) {
        return (history: const .empty(), live: const .empty());
      }

      final anchorIndex = items.indexWhere((item) => item.eventId == anchor);

      if (anchorIndex == -1) {
        return (history: const .empty(), live: items);
      }

      return (
        history: items.take(anchorIndex).toIList().reversed.toIList(),
        live: items.skip(anchorIndex).toIList(),
      );
    }, [controllerData, anchorId.value]);

    useEffect(
      () {
        const loadThreshold = 500.0;
        const readThreshold = 50.0;

        Future<void> checkPosition() async {
          if (!scrollController.hasClients) return;

          final position = scrollController.position;

          final isAtBottom = position.extentBefore <= readThreshold;
          if (isAtBottom != atBottom.value) atBottom.value = isAtBottom;

          if (position.extentAfter <= loadThreshold) {
            await paginate(.backward);
          } else if (contextualEvent.value != null &&
              position.extentBefore <= loadThreshold) {
            await paginate(.forward);
          } else if (position.extentBefore <= readThreshold) {
            await markRead();
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

    Future<void> jumpToId(String itemId) async {
      if (!scrollController.hasClients) return;

      if (anchorId.value != itemId) {
        final completer = Completer<BuildContext>();
        anchorMountedCompleter.value = completer;
        pendingAnchorTarget.value = itemId;
        contextualEvent.value = itemId;

        final context = await completer.future;
        if (!context.mounted) return;

        await Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const .new(milliseconds: 700),
          curve: Curves.easeInOut,
        );
        return;
      }

      final context = anchorItemKey.currentContext;
      if (context != null && context.mounted) {
        await Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const .new(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    }

    Future<void> jumpToBottom() async {
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
    }

    return .new(
      historyItems: split.history,
      liveItems: split.live,
      centerKey: centerKey,
      anchorItemKey: anchorItemKey,
      scrollController: scrollController,
      atBottom: atBottom.value,
      jumpToId: jumpToId,
      jumpToBottom: jumpToBottom,
    );
  }
}
