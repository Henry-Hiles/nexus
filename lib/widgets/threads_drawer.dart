import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/thread_list.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/thread_events.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/event_preview.dart";
import "package:nexus/widgets/timestamp.dart";

final class const ThreadsDrawer(
  final String roomId, {
  required final void Function(String threadRoot) onOpenThread,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(
      RoomsController.provider.select(
        (rooms) => rooms[roomId]?.threads ?? const .empty(),
      ),
    );
    final serverProvider = ThreadListController.provider(roomId);
    final server = ref.watch(serverProvider);
    final theme = Theme.of(context);

    void open(String threadRoot) {
      Navigator.of(context).pop();
      onOpenThread(threadRoot);
    }

    return Drawer(
      width: 400,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: Icon(Icons.forum),
          title: Text("Threads"),
          actionsPadding: .only(right: 4),
          actions: [
            IconButton(
              onPressed: Scaffold.of(context).closeEndDrawer,
              icon: Icon(Icons.close),
              tooltip: "Close threads",
            ),
          ],
        ),
        body: switch (server) {
          AsyncError(:final error, :final stackTrace) => ErrorDialog(
            error,
            stackTrace,
          ),
          AsyncValue(hasValue: true, value: final nextBatch)
              when threads.isNotEmpty =>
            ListView.builder(
              padding: .all(8),
              itemCount: threads.length + (nextBatch == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == threads.length) {
                  return Center(
                    child: TextButton(
                      onPressed: server.isLoading
                          ? null
                          : () => ref
                                .read(serverProvider.notifier)
                                .loadMore()
                                .onError(showError),
                      child: Text("Load more"),
                    ),
                  );
                }

                final (:root, :info) = threads[index];
                return Card(
                  margin: .symmetric(vertical: 4),
                  color: theme.colorScheme.surfaceContainerHigh,
                  clipBehavior: .antiAlias,
                  child: InkWell(
                    onTap: () => open(root.eventId),
                    child: Padding(
                      padding: .symmetric(vertical: 8, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: .start,
                        spacing: 4,
                        children: [
                          EventPreview(root.rowId, roomId: roomId),
                          Row(
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.forum,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              Text(
                                "${info.count} ${info.count == 1 ? "reply" : "replies"}",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Spacer(),
                              if (info.latest case final latest?) ...[
                                Text(
                                  "Last active",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                Timestamp(latest.timestamp),
                              ],
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          AsyncLoading() => Loading(),
          AsyncData() => Center(
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface,
                ),
                SizedBox(height: 12),
                Text("No threads", style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
        },
      ),
    );
  }
}
