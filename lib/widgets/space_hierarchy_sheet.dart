import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/space_hierarchy.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/join_room.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/extensions/show_leave_room_sheet.dart";
import "package:nexus/helpers/extensions/with_progress_snackbar.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/space_hierarchy.dart";
import "package:nexus/widgets/add_space_rooms_sheet.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/knock_sheet.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/room_summary_sheet.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const SpaceHierarchySheet(final String spaceId, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedIds = ref.watch(
      RoomsController.provider.select((rooms) => rooms.keys.toISet()),
    );

    void showSummary(SpaceHierarchyRoom room, SpaceHierarchyChild child) =>
        context.showAdaptiveSheet(
          (_) => RoomSummarySheet(
            room.summary,
            via: joinedIds.contains(room.summary.roomId) ? null : child.via,
          ),
        );

    Widget membershipButton(
      SpaceHierarchyRoom room,
      SpaceHierarchyChild child, {
      required String name,
    }) => joinedIds.contains(room.summary.roomId)
        ? TextButton(
            onPressed: () =>
                context.showLeaveRoomSheet(room.summary.roomId, name: name),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text("Leave"),
          )
        : room.summary.mustKnock(joinedIds)
        ? TextButton(
            onPressed: () => context.showAdaptiveSheet(
              (_) =>
                  KnockSheet(room.summary.roomId, name: name, via: child.via),
            ),
            child: const Text("Knock"),
          )
        : TextButton(
            onPressed: () => context.joinRoom(
              .new(roomIdOrAlias: room.summary.roomId, via: child.via),
              name: name,
            ),
            child: const Text("Join"),
          );

    Widget removeButton(
      String spaceId,
      String roomId, {
      required String name,
      required String spaceName,
    }) => Consumer(
      builder: (context, ref, _) {
        final mutation = SpaceHierarchyController.removeChildMutation((
          spaceId,
          roomId,
        ));
        if (ref.watch(mutation).isPending) {
          return const Padding(
            padding: .all(12),
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(),
            ),
          );
        }

        return IconButton(
          tooltip: "Remove from space",
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => context.showAdaptiveSheet(
            (context) => SheetLayout(
              title: const Text("Remove Room"),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final container = ProviderScope.containerOf(context);
                    mutation.run(
                      container,
                      (_) => context.withProgressSnackbar(
                        "Removing $name from $spaceName...",
                        () async {
                          await container
                              .read(ClientController.provider.notifier)
                              .setState(
                                .new(
                                  roomId: spaceId,
                                  type: EventType.spaceChild.type,
                                  stateKey: roomId,
                                  content: const Content(),
                                ),
                              );
                          container.invalidate(
                            SpaceHierarchyController.provider(spaceId),
                          );
                        },
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text("Remove"),
                ),
              ],
              children: [
                Text(
                  "Are you sure you want to remove \"$name\" from \"$spaceName\"? Its members will stay in it.",
                ),
              ],
            ),
          ),
        );
      },
    );

    Widget level(
      String spaceId,
      SpaceHierarchy hierarchy,
      ISet<String> ancestors,
    ) => HookConsumer(
      builder: (context, ref, _) {
        final loadingMore = useState(false);
        final adding = ref
            .watch(SpaceHierarchyController.addChildrenMutation(spaceId))
            .isPending;
        final canManage = ref.watch(
          PowerLevelController.provider(
            .state(eventType: .spaceChild, roomId: spaceId),
          ),
        );

        final byId = IMap.fromValues(
          keyMapper: (room) => room.summary.roomId,
          values: hierarchy.rooms,
        );
        final spaceName =
            byId[spaceId]?.summary.name ??
            byId[spaceId]?.summary.canonicalAlias ??
            "Unnamed Space";
        final children = (byId[spaceId]?.children ?? const .empty())
            .map(
              (child) => switch (byId[child.roomId]) {
                // Skip spaces that contain themselves somewhere up the tree.
                final room? when !ancestors.contains(child.roomId) => (
                  child,
                  room,
                ),
                _ => null,
              },
            )
            .nonNulls
            // Suggested rooms first, then sorted by member count
            .sorted((a, b) {
              if (a.$1.suggested != b.$1.suggested) {
                return a.$1.suggested ? -1 : 1;
              }
              return (b.$2.summary.joinedMembers ?? 0).compareTo(
                a.$2.summary.joinedMembers ?? 0,
              );
            });

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            for (final (child, room) in children)
              if (room.summary.roomType != RoomType.space)
                Builder(
                  builder: (context) {
                    final summary = room.summary;
                    final name =
                        summary.name ??
                        summary.canonicalAlias ??
                        "Unnamed Room";

                    return ListTile(
                      leading: AvatarOrHash(
                        summary.avatarUrl,
                        name,
                        fallback: const Icon(Icons.numbers),
                      ),
                      title: Text(name, maxLines: 1, overflow: .ellipsis),
                      subtitle: summary.topic == null
                          ? null
                          : Text(
                              summary.topic!,
                              maxLines: 2,
                              overflow: .ellipsis,
                            ),
                      onTap: () => showSummary(room, child),
                      trailing: Row(
                        mainAxisSize: .min,
                        children: [
                          membershipButton(room, child, name: name),
                          if (canManage)
                            removeButton(
                              spaceId,
                              summary.roomId,
                              name: name,
                              spaceName: spaceName,
                            ),
                        ],
                      ),
                    );
                  },
                ),
            for (final (child, room) in children)
              if (room.summary.roomType == RoomType.space)
                HookConsumer(
                  builder: (context, ref, _) {
                    final expanded = useState(false);
                    final summary = room.summary;
                    final name =
                        summary.name ??
                        summary.canonicalAlias ??
                        "Unnamed Space";
                    final joined = joinedIds.contains(summary.roomId);

                    return Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        ListTile(
                          onTap: joined
                              ? () => expanded.value = !expanded.value
                              : () => showSummary(room, child),
                          leading: AvatarOrHash(
                            summary.avatarUrl,
                            name,
                            fallback: const Icon(Icons.workspaces),
                          ),
                          title: Text(name, maxLines: 1, overflow: .ellipsis),
                          subtitle: summary.topic == null
                              ? null
                              : Text(
                                  summary.topic!,
                                  maxLines: 2,
                                  overflow: .ellipsis,
                                ),
                          trailing: Row(
                            mainAxisSize: .min,
                            children: [
                              if (joined)
                                AnimatedRotation(
                                  turns: expanded.value ? 0.5 : 0,
                                  duration: Durations.medium2,
                                  child: const Icon(Icons.expand_more),
                                ),
                              membershipButton(room, child, name: name),
                              if (canManage)
                                removeButton(
                                  spaceId,
                                  summary.roomId,
                                  name: name,
                                  spaceName: spaceName,
                                ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: Durations.medium2,
                          curve: Curves.easeInOut,
                          alignment: .topCenter,
                          child: joined && expanded.value
                              ? Padding(
                                  // Indented so it's clear which rooms are in which space
                                  padding: const .only(left: 16),
                                  child: ref
                                      .watch(
                                        SpaceHierarchyController.provider(
                                          summary.roomId,
                                        ),
                                      )
                                      .betterWhen(
                                        skipLoadingOnRefresh: true,
                                        loading: () =>
                                            const Loading(dimension: 24),
                                        data: (hierarchy) => level(
                                          summary.roomId,
                                          hierarchy,
                                          ancestors.add(child.roomId),
                                        ),
                                      ),
                                )
                              : const SizedBox(width: .infinity),
                        ),
                      ],
                    );
                  },
                ),
            if (hierarchy.nextBatch != null || canManage)
              Row(
                mainAxisAlignment: .center,
                spacing: 8,
                children: [
                  if (hierarchy.nextBatch != null)
                    TextButton(
                      onPressed: loadingMore.value
                          ? null
                          : () async {
                              loadingMore.value = true;
                              await ref
                                  .read(
                                    SpaceHierarchyController.provider(spaceId)
                                        .notifier,
                                  )
                                  .loadMore()
                                  .onError(showError);
                              if (context.mounted) loadingMore.value = false;
                            },
                      child: const Text("Load more"),
                    ),
                  if (canManage)
                    TextButton.icon(
                      onPressed: adding
                          ? null
                          : () => context.showAdaptiveSheet(
                              (_) => AddSpaceRoomsSheet(
                                spaceId,
                                spaceName: spaceName,
                                existing:
                                    (byId[spaceId]?.children ?? const .empty())
                                        .map((child) => child.roomId)
                                        .toISet(),
                              ),
                            ),
                      icon: adding
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.add),
                      label: const Text("Add rooms"),
                    ),
                ],
              ),
          ],
        );
      },
    );

    return ref
        .watch(SpaceHierarchyController.provider(spaceId))
        .betterWhen(
          skipLoadingOnRefresh: true,
          data: (hierarchy) {
            final space = hierarchy.rooms
                .where((room) => room.summary.roomId == spaceId)
                .firstOrNull
                ?.summary;

            return SheetLayout(
              title: Row(
                spacing: 12,
                children: [
                  if (space?.avatarUrl case final avatarUrl?)
                    ExpandableImage(
                      .new(mxc: avatarUrl),
                      downloadFilename:
                          space?.name ?? space?.canonicalAlias ?? spaceId,
                      child: AvatarOrHash(avatarUrl, "", dimension: 32),
                    ),
                  Expanded(
                    child: Text(
                      space?.name ?? space?.canonicalAlias ?? "Unnamed Space",
                      overflow: .ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Close"),
                ),
              ],
              children: [
                level(spaceId, hierarchy, .new([spaceId])),
              ],
            );
          },
        );
  }
}
