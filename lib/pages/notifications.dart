import "dart:async";

import "package:m3e_buttons/m3e_buttons.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/notifications.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/renderers/event.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const NotificationsPage({
  final String? highlightedEventId,
  final bool defaultToAllNotifications = false,
  super.key,
}) extends HookConsumerWidget {
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
    final unreadTypeIndex = useState(defaultToAllNotifications ? 1 : 0);

    final highlightedId = useState(highlightedEventId);
    final listController = useRef(ListController());
    final scrollController = useScrollController();

    final provider = NotificationsController.provider((
      options.values.toList()[unreadTypeIndex.value],
      null,
    ));
    final notifications = ref.watch(provider);
    final notifier = ref.watch(provider.notifier);

    useEffect(() {
      if (highlightedId.value == null) return null;
      Timer? timer;

      void listener() =>
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!listController.value.isAttached) return;

            final notifications = await ref.watch(provider.future);

            final index = notifications.indexWhere(
              (element) => element.eventId == highlightedId.value!,
            );

            if (index == -1) return;

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
            listController.value.removeListener(listener);
          });

      listController.value.addListener(listener);
      return timer?.cancel;
    }, []);

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

    return Scaffold(
      appBar: Appbar(title: Text("Notifications")),
      body: Stack(
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
                              final event = value[index];
                              final isHighlighted =
                                  event.eventId == highlightedId.value;

                              return Padding(
                                padding: .only(top: 8),
                                child: HighlightWrapper(
                                  InkWell(
                                    onTap: () {
                                      // TODO: Jump to event
                                    },
                                    child: EventRenderer(event),
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
      ),
    );
  }
}
