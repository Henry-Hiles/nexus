import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/room_directory.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/main.dart";
import "package:nexus/helpers/extensions/room_summary_display.dart";
import "package:nexus/widgets/rooms/add_directory_server_sheet.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/rooms/room_summary_sheet.dart";
import "package:nexus/widgets/common/divider_text.dart";
import "package:nexus/widgets/common/error_dialog.dart";
import "package:nexus/widgets/common/loading.dart";
import "package:nexus/widgets/common/m3e_rail_theme.dart";
import "package:nexus/widgets/rooms/room_directory_card.dart";

class const ExplorePage({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownServer = ref.watch(
      ClientStateController.provider.select(
        (state) => state?.userId?.serverName,
      ),
    );
    final savedServers = ref
        .watch(
          SettingsController.provider.select(
            (settings) => settings.value?.directoryServers,
          ),
        )
        ?.where((server) => server != ownServer)
        .toIList();

    // Null is the user's own server
    final selected = useState<String?>(null);
    final servers = IList<String?>([null, ...?savedServers]);
    String labelOf(String? server) => server ?? ownServer ?? "Home";
    IconData iconOf(String? server) => server == null ? Icons.home : Icons.dns;

    final current = servers[max(0, servers.indexOf(selected.value))];
    final provider = RoomDirectoryController.provider(current);
    final loadMore = RoomDirectoryController.loadMoreMutation(current);
    final loadingMore = ref.watch(loadMore).isPending;
    final directory = ref.watch(provider);
    final theme = Theme.of(context);

    final via = IList([?current ?? ownServer]);

    Future<void> addServer() async {
      final server = await context.showAdaptiveSheet<String>(
        (_) => AddDirectoryServerSheet(
          existing: .new([?ownServer, ...servers.nonNulls]),
        ),
      );
      if (server == null) return;

      final settings = await ref.read(SettingsController.provider.future);
      await ref
          .read(SettingsController.provider.notifier)
          .set(
            settings.copyWith(
              directoryServers: settings.directoryServers.add(server),
            ),
          );
      if (context.mounted) selected.value = server;
    }

    Future<void> removeServer(String server) async {
      selected.value = null;
      final settings = await ref.read(SettingsController.provider.future);
      await ref
          .read(SettingsController.provider.notifier)
          .set(
            settings.copyWith(
              directoryServers: settings.directoryServers.remove(server),
            ),
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        final searchBar = SearchAnchor.bar(
          barHintText: "Search...",
          isFullScreen: !isWide,
          suggestionsBuilder: (suggestionsContext, controller) async {
            final text = controller.text.trim();
            if (text.isEmpty) return const [];

            // Each search hits the server, so wait for the user to stop typing
            await Future.delayed(Durations.long2);
            if (controller.text.trim() != text) return const [];

            try {
              final directory = await ref
                  .read(ClientController.provider.notifier)
                  .getRoomDirectory(
                    .new(
                      server: current,
                      limit: 20,
                      filter: .new(genericSearchTerm: text),
                    ),
                  );
              return directory.rooms.map(
                (summary) => Consumer(
                  builder: (_, ref, _) {
                    final joined = ref.watch(
                      RoomsController.provider.select(
                        (rooms) => rooms.containsKey(summary.roomId),
                      ),
                    );

                    return ListTile(
                      onTap: () {
                        Navigator.of(suggestionsContext).pop();
                        controller.text = "";

                        context.showAdaptiveSheet(
                          (_) => RoomSummarySheet(
                            summary,
                            via: joined ? null : via,
                          ),
                        );
                      },
                      leading: AvatarOrHash(
                        summary.avatarUrl,
                        summary.displayName,
                        fallback: Icon(summary.icon),
                      ),
                      title: Text(summary.displayName),
                      subtitle: Text(
                        [
                          summary.details,
                          if (joined) "Joined",
                        ].where((part) => part.isNotEmpty).join(" · "),
                      ),
                    );
                  },
                ),
              );
            } catch (error) {
              return [
                ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text("Couldn't search this server"),
                  subtitle: Text(error.toString()),
                ),
              ];
            }
          },
        );

        final results = CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const .all(16),
              sliver: SliverList.list(
                children: [
                  if (!isWide)
                    Padding(
                      padding: const .only(bottom: 12),
                      child: SingleChildScrollView(
                        scrollDirection: .horizontal,
                        child: Row(
                          spacing: 8,
                          children: [
                            ...servers.map(
                              (server) => ChoiceChip(
                                avatar: Icon(iconOf(server)),
                                label: Text(labelOf(server)),
                                selected: current == server,
                                onSelected: (_) => selected.value = server,
                              ),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.add),
                              label: const Text("Add server"),
                              onPressed: () => addServer().onError(showError),
                            ),
                          ],
                        ),
                      ),
                    ),
                  searchBar,
                  const SizedBox(height: 16),
                  Text(switch (directory.value?.totalRoomCountEstimate) {
                    final count? when count > 0 => "Popular Rooms ($count)",
                    _ => "Popular Rooms",
                  }, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            ...switch (directory) {
              AsyncData(:final value) when value.rooms.isEmpty => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No rooms found",
                          style: theme.textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              AsyncData(:final value) || AsyncLoading(:final value?) => [
                SliverPadding(
                  padding: const .symmetric(horizontal: 16),
                  sliver: SliverLayoutBuilder(
                    builder: (_, constraints) => SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: max(
                          1,
                          (constraints.crossAxisExtent + 12) ~/ (280 + 12),
                        ),
                        mainAxisExtent: 210,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: value.rooms.length,
                      itemBuilder: (_, index) =>
                          RoomDirectoryCard(value.rooms[index], via: via),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const .all(16),
                  sliver: SliverToBoxAdapter(
                    child: value.nextBatch == null
                        ? null
                        : Center(
                            child: TextButton(
                              onPressed: loadingMore
                                  ? null
                                  : () => loadMore
                                        .run(
                                          ref,
                                          (transaction) => transaction
                                              .get(provider.notifier)
                                              .loadMore(),
                                        )
                                        .onError(showError),
                              child: const Text("Load more"),
                            ),
                          ),
                  ),
                ),
              ],
              AsyncError(:final error, :final stackTrace) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorDialog(error, stackTrace, provider: provider),
                ),
              ],
              AsyncLoading() => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Loading(),
                ),
              ],
            },
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text("Explore Rooms"),
            actionsPadding: const .symmetric(horizontal: 12),
            actions: [
              if (current case final server?)
                IconButton(
                  tooltip: "Remove server",
                  onPressed: () => removeServer(server).onError(showError),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    M3ERailTheme(
                      builder: (_) => NavigationRailM3E(
                        type: .alwaysExpand,
                        scrollable: true,
                        fab: .new(
                          icon: const Icon(Icons.add),
                          label: "Add server",
                          tooltip: "Add a server to browse",
                          onPressed: () => addServer().onError(showError),
                        ),
                        sections: [
                          .new(
                            header: const DividerText("Servers"),
                            destinations: servers
                                .map(
                                  (server) => NavigationRailM3EDestination(
                                    icon: Icon(iconOf(server)),
                                    label: labelOf(server),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        selectedIndex: servers.indexOf(current),
                        onDestinationSelected: (index) =>
                            selected.value = servers[index],
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(child: results),
                  ],
                )
              : results,
        );
      },
    );
  }
}
