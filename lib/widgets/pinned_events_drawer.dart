import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/pinned_events_controller.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/renderers/event.dart";

class PinnedEventsDrawer extends HookConsumerWidget {
  final String roomId;
  final IList<PopupMenuEntry> Function(Event event) getEventOptions;
  final Future<void> Function(String eventId) jumpToId;
  const PinnedEventsDrawer(
    this.roomId, {
    required this.getEventOptions,
    required this.jumpToId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsProvider = ref.watch(PinnedEventsController.provider(roomId));
    final theme = Theme.of(context);

    return Drawer(
      width: 400,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: Icon(Icons.push_pin),
          title: Text("Pinned Events"),
          actionsPadding: .only(right: 4),
          actions: [
            IconButton(
              onPressed: Scaffold.of(context).closeEndDrawer,
              icon: Icon(Icons.close),
              tooltip: "Close pinned events",
            ),
          ],
        ),
        body: switch (pinsProvider) {
          AsyncData(:final value) when value.isEmpty => Center(
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface,
                ),
                SizedBox(height: 12),
                Text("No pinned events", style: theme.textTheme.headlineSmall),
              ],
            ),
          ),
          AsyncData(:final value) ||
          AsyncLoading(:final value?) => ListView.builder(
            padding: .all(8),
            reverse: true,
            itemCount: value.length,
            itemBuilder: (context, index) {
              final event = value.reversed[index];

              return InkWell(
                borderRadius: .circular(12),
                onTap: () {
                  Navigator.pop(context);
                  jumpToId(event.eventId);
                },
                child: Padding(
                  padding: .symmetric(vertical: 4),
                  child: EventRenderer(
                    event,
                    maxLines: 2,
                    isGrouped: false,
                    getEventOptions: getEventOptions,
                  ),
                ),
              );
            },
          ),
          AsyncLoading() => Loading(),
          AsyncError(:final error, :final stackTrace) => ErrorDialog(
            error,
            stackTrace,
          ),
        },
      ),
    );
  }
}
