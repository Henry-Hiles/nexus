import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/event_search.dart";
import "package:nexus/helpers/hooks/chat_scroll.dart";
import "package:nexus/main.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/renderers/event.dart";

final class const SearchDrawer(
  final String roomId, {
  required final IList<PopupMenuEntry> Function(Event event) getEventOptions,
  required final JumpToEvent jumpToEvent,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState("");
    final provider = EventSearchController.provider((
      roomId: roomId,
      query: query.value,
    ));
    final results = ref.watch(provider);
    final theme = Theme.of(context);

    void search() {
      final text = controller.text.trim();

      // The provider is keyed on the query, so searching again needs a refetch
      if (text == query.value) {
        ref.invalidate(provider, asReload: true);
      } else {
        query.value = text;
      }
    }

    Widget placeholder(IconData icon, String text) => Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurface),
          SizedBox(height: 12),
          Text(text, style: theme.textTheme.headlineSmall),
        ],
      ),
    );

    return Drawer(
      width: 400,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          leading: Icon(Icons.search),
          title: Text("Search"),
          actionsPadding: .only(right: 4),
          actions: [
            IconButton(
              onPressed: Scaffold.of(context).closeEndDrawer,
              icon: Icon(Icons.close),
              tooltip: "Close search",
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: .symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: .search,
                onSubmitted: (_) => search(),
                decoration: .new(
                  hintText: "Search this room",
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: search,
                    icon: Icon(Icons.arrow_forward),
                    tooltip: "Search",
                  ),
                ),
              ),
            ),
            Expanded(
              child: query.value.isEmpty
                  ? placeholder(Icons.search, "Search for events")
                  : switch (results) {
                      AsyncData(:final value) when value.rowIds.isEmpty =>
                        placeholder(Icons.search_off, "No results"),
                      AsyncData(:final value) ||
                      AsyncLoading(:final value?) => ListView.builder(
                        padding: .all(8),
                        itemCount:
                            value.rowIds.length +
                            (value.nextBatch == null ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == value.rowIds.length) {
                            return Center(
                              child: TextButton(
                                onPressed: results.isLoading
                                    ? null
                                    : () => ref
                                          .read(provider.notifier)
                                          .paginate()
                                          .onError(showError),
                                child: Text("Load more"),
                              ),
                            );
                          }

                          final rowId = value.rowIds[index];
                          return InkWell(
                            borderRadius: .circular(12),
                            onTap: () {
                              Navigator.of(context).pop();
                              jumpToEvent(rowId);
                            },
                            child: Padding(
                              padding: .symmetric(vertical: 4),
                              child: IgnorePointer(
                                child: EventRenderer(
                                  rowId,
                                  roomId: roomId,
                                  maxLines: 2,
                                  getEventOptions: getEventOptions,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AsyncLoading() => Loading(),
                      AsyncError(:final error, :final stackTrace) =>
                        ErrorDialog(error, stackTrace),
                    },
            ),
          ],
        ),
      ),
    );
  }
}
