import "dart:math";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/reactions.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/helpers/extensions/show_image_viewer.dart";
import "package:nexus/widgets/reactions/reaction_key.dart";

/// Every reaction to an event in tabs, each listing who reacted with it.
class const ReactionsPopover(
  final Event event, {
  final String? initialReaction,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactions = ref.watch(
      ReactionsController.provider(
        .new(roomId: event.roomId, eventRowId: event.rowId),
      ),
    );
    // Ordered like the reaction row on the timeline
    final order = event.reactions.keys.toIList();
    final keys =
        reactions.value?.keys.toIList().sortOrdered(
          (a, b) => order.indexOf(a).compareTo(order.indexOf(b)),
        ) ??
        const .empty();

    final vsync = useSingleTickerProvider(keys: [keys.length]);
    final tabController = useMemoized(
      () => TabController(
        length: keys.length,
        initialIndex: keys
            .indexOf(initialReaction ?? "")
            .clamp(0, max(0, keys.length - 1)),
        vsync: vsync,
      ),
      [keys.length],
    );
    useEffect(() => tabController.dispose, [tabController]);
    useListenable(tabController);

    return reactions.betterWhen(
      skipLoadingOnReload: true,
      data: (reactions) {
        if (keys.isEmpty) return SizedBox.shrink();

        final reaction = keys[tabController.index];

        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: .start,
              tabs: keys.map((reaction) {
                void expand() => context.showImageViewer(
                  ref,
                  .new(mxc: Uri.parse(reaction)),
                  downloadFilename: reaction.split("/").last,
                );
                final isImage = reaction.startsWith("mxc://");

                return GestureDetector(
                  onSecondaryTap: isImage ? expand : null,
                  onLongPress: isImage ? expand : null,
                  child: Tab(
                    child: Row(
                      mainAxisSize: .min,
                      spacing: 8,
                      children: [
                        ReactionKey(reaction, height: 20),
                        Text(reactions[reaction]!.senders.length.toString()),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Flexible(
              child: AnimatedSize(
                duration: Durations.medium2,
                curve: Curves.easeInOutCubicEmphasized,
                alignment: .topCenter,
                child: SingleChildScrollView(
                  key: ValueKey(reaction),
                  padding: .symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: reactions[reaction]!.senders
                        .map(
                          (userId) => Consumer(
                            builder: (context, ref, _) {
                              final member = ref
                                  .watch(
                                    UserController.provider(
                                      .new(
                                        roomId: event.roomId,
                                        userId: userId,
                                      ),
                                    ),
                                  )
                                  .value;
                              final name =
                                  member?.displayName ?? userId.localpart;

                              return ListTile(
                                leading: AvatarOrHash(
                                  member?.avatarUrl,
                                  name,
                                  dimension: 40,
                                ),
                                title: Text(name, overflow: .ellipsis),
                                subtitle: Text(userId, overflow: .ellipsis),
                                onTap: () => context.showUserPopover(
                                  userId,
                                  roomId: event.roomId,
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
