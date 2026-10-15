import "dart:async";

import "package:m3e_buttons/m3e_buttons.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:nexus/controllers/notifications.dart";
import "package:nexus/helpers/extensions/focus_room.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/nav_page.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const NotificationsList({super.key})
    extends HookConsumerWidget
    implements NavPage {
  @override
  String get title => "Notifications";

  @override
  IconData get icon => Icons.notifications;

  @override
  Null badgeCount(_) => null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = <M3EToggleButtonGroupAction, UnreadType>{
      M3EToggleButtonGroupAction(
        checkedLabel: Text("Mentions"),
        icon: Icon(Icons.alternate_email),
      ): .highlight,
      M3EToggleButtonGroupAction(
        checkedLabel: Text("All Notifications"),
        icon: Icon(Icons.notifications),
      ): .notify,
    };
    final allNotificationsIndex = options.values.toList().indexOf(.notify);

    final initialRequest = useMemoized(
      () => ref.read(NotificationRequestController.provider),
    );
    final unreadTypeIndex = useState(
      initialRequest == null ? 0 : allNotificationsIndex,
    );
    final highlightedId = useState(initialRequest);
    final listController = useRef(ListController());
    final scrollController = useScrollController();

    final provider = NotificationsController.provider((
      options.values.toList()[unreadTypeIndex.value],
      null,
    ));
    final notifications = ref.watch(provider);
    final notifier = ref.watch(provider.notifier);

    void consumeRequest() => Future.microtask(
      ref.read(NotificationRequestController.provider.notifier).consume,
    );

    useEffect(() {
      if (initialRequest != null) consumeRequest();
      return null;
    }, []);

    ref.listen(NotificationRequestController.provider, (_, next) {
      if (next == null) return;
      unreadTypeIndex.value = allNotificationsIndex;
      highlightedId.value = next;
      consumeRequest();
    });

    useEffect(() {
      final target = highlightedId.value;
      if (target == null) return null;

      Timer? timer;
      var done = false;

      void listener() => WidgetsBinding.instance.addPostFrameCallback((
        _,
      ) async {
        if (done || !listController.value.isAttached) return;

        final notifications = await ref.read(provider.future);

        final index = notifications.indexWhere((tuple) => tuple.$1 == target);

        if (done || index == -1) return;
        done = true;
        listController.value.removeListener(listener);

        listController.value.animateToItem(
          index: index,
          scrollController: scrollController,
          alignment: 0.5,
          duration: (_) => .new(milliseconds: 700),
          curve: (_) => Curves.easeInOut,
        );
        timer = Timer(.new(seconds: 1), () {
          highlightedId.value = null;
        });
      });

      listController.value.addListener(listener);
      // The list may already be laid out, in which case no change is notified
      listener();

      return () {
        done = true;
        listController.value.removeListener(listener);
        timer?.cancel();
      };
    }, [highlightedId.value]);

    useEffect(() {
      Future<void> listener() async {
        if (!scrollController.hasClients || notifications.isLoading) return;

        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent) {
          await notifier.loadOlder();
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController, notifications]);

    return Stack(
      children: [
        Column(
          children: [
            if (notifications is AsyncLoading && notifications.value != null)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: switch (notifications) {
                AsyncData(:final value) || AsyncLoading(:final value?) =>
                  value.isEmpty
                      ? Center(
                          child: Text(
                            "No notifications yet",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        )
                      : SuperListView.builder(
                          listController: listController.value,
                          controller: scrollController,
                          itemCount: value.length,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          reverse: true,
                          itemBuilder: (context, index) {
                            final (rowId, roomId) = value[index];
                            final isHighlighted = rowId == highlightedId.value;

                            return Padding(
                              padding: .only(top: 8),
                              child: HighlightWrapper(
                                InkWell(
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    if (navigator.canPop()) navigator.pop();

                                    await ref.focusRoom(roomId, rowId);
                                  },
                                  child: IgnorePointer(
                                    child: EventRenderer(rowId, roomId: roomId),
                                  ),
                                ),
                                isHighlighted: isHighlighted,
                              ),
                            );
                          },
                        ),
                AsyncLoading() => const Loading(),
                AsyncError(:final error, :final stackTrace) => ErrorDialog(
                  error,
                  stackTrace,
                ),
              },
            ),
          ],
        ),
        Align(
          alignment: .topRight,
          child: Padding(
            padding: .all(16),
            child: M3EToggleButtonGroup(
              selectedIndex: unreadTypeIndex.value,
              onSelectedIndexChanged: (index) =>
                  unreadTypeIndex.value = index ?? unreadTypeIndex.value,
              actions: options.keys.toList(),
            ),
          ),
        ),
      ],
    );
  }
}
