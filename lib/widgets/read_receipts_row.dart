import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/read_receipts.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/avatar_ring.dart";
import "package:nexus/widgets/read_receipts_sheet.dart";

class const ReadReceiptsRow(
  final String eventId, {
  required final ChatParams chat,
  super.key,
}) extends ConsumerWidget {
  static const avatarSize = 24.0;
  static const overlap = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final receipts = ref.watch(
      ReadReceiptsController.provider(chat)
          .select((receipts) => receipts[eventId] ?? const .empty()),
    );

    return AnimatedSize(
      duration: Durations.medium2,
      curve: Curves.easeInOutCubicEmphasized,
      alignment: .topRight,
      child: receipts.isEmpty
          ? const SizedBox(width: .infinity)
          : Padding(
              // Clear of the scrollbar
              padding: .only(right: 16, bottom: 2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const width = avatarSize + AvatarRing.ringWidth * 2;
                  final fits =
                      (constraints.maxWidth - width) ~/ (width - overlap) + 1;

                  // If they don't all fit, the last spot shows how many more there are
                  final shown = receipts.length <= fits
                      ? receipts.length
                      : fits - 1;

                  return Align(
                    alignment: .centerRight,
                    child: Wrap(
                      spacing: -overlap,
                      children: [
                        ...receipts
                            .take(shown)
                            .map(
                              (receipt) => Consumer(
                                builder: (context, ref, _) {
                                  final member = ref
                                      .watch(
                                        UserController.provider(
                                          .new(
                                            roomId: chat.roomId,
                                            userId: receipt.userId,
                                          ),
                                        ),
                                      )
                                      .value;
                                  final name =
                                      member?.displayName ??
                                      receipt.userId.localpart;

                                  return AvatarRing(
                                    tooltip: name,
                                    onTap: () => context.showUserPopover(
                                      receipt.userId,
                                      roomId: chat.roomId,
                                    ),
                                    child: AvatarOrHash(
                                      member?.avatarUrl,
                                      name,
                                      dimension: avatarSize,
                                    ),
                                  );
                                },
                              ),
                            ),
                        if (receipts.length > shown)
                          AvatarRing(
                            tooltip: "Show everyone who has read up to here",
                            onTap: () => context.showAdaptiveSheet(
                              (_) => ReadReceiptsSheet(eventId, chat: chat),
                            ),
                            child: ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Text(
                                  "+${receipts.length - shown}",
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
