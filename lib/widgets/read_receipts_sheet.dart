import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/read_receipts.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/show_user_popover.dart";
import "package:nexus/widgets/avatar_or_hash.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Everyone who has read up to an event, kept up to date while open.
class const ReadReceiptsSheet(
  final String eventId, {
  required final ChatParams chat,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SheetLayout(
    title: Text("Read by"),
    actions: [
      TextButton(onPressed: Navigator.of(context).pop, child: Text("Close")),
    ],
    children: ref
        .watch(
          ReadReceiptsController.provider(chat)
              .select((receipts) => receipts[eventId] ?? const .empty()),
        )
        .map(
          (receipt) => Consumer(
            builder: (context, ref, _) {
              final member = ref
                  .watch(
                    UserController.provider(
                      .new(roomId: chat.roomId, userId: receipt.userId),
                    ),
                  )
                  .value;
              final name = member?.displayName ?? receipt.userId.localpart;

              return ListTile(
                leading: AvatarOrHash(member?.avatarUrl, name, dimension: 40),
                title: Text(name, overflow: .ellipsis),
                subtitle: Text(receipt.userId, overflow: .ellipsis),
                onTap: () => context.showUserPopover(
                  receipt.userId,
                  roomId: chat.roomId,
                ),
              );
            },
          ),
        )
        .toList(),
  );
}
