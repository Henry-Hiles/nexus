import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/pinned_ids.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/recent_emoji.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/emoji_picker.dart";
import "package:nexus/main.dart";

extension BuildEventOptions on Event {
  IList<PopupMenuEntry> buildEventOptions({
    required BuildContext context,
    required WidgetRef ref,
    required String roomId,
    required String userId,
    required void Function(Event, RelationType) onRelation,
  }) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;

    final notifier = ref.read(
      RoomChatController.provider((roomId, null)).notifier,
    );
    final client = ref.read(ClientController.provider.notifier);

    final isPinned = ref
        .watch(PinnedIdsController.provider(roomId))
        .contains(eventId);

    Future<void> sendReaction(String emoji) async {
      await notifier.sendReaction(emoji, this).onError(showError);

      await ref
          .read(RecentEmojiController.provider.notifier)
          .add(emoji)
          .onError(showError);
    }

    void showReasonDialog({
      required String title,
      required String description,
      required String action,
      required Future<void> Function(String reason) onConfirm,
    }) {
      showDialog(
        context: context,
        builder: (context) => HookBuilder(
          builder: (context) {
            final reasonController = useTextEditingController();

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Text(description),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    textCapitalization: .sentences,
                    decoration: .new(labelText: "Reason (optional)"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final reason = reasonController.text;
                    Navigator.of(context).pop();

                    onConfirm(reason).onError(showError);
                  },
                  child: Text(action),
                ),
              ],
            );
          },
        ),
      );
    }

    return .new([
      if (ref.watch(
        PowerLevelController.provider(
          .new(eventType: .reaction, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          enabled: false,
          child: IconTheme(
            data: theme.iconTheme,
            child: Row(
              children: [
                for (final emoji in {
                  ...ref
                      .watch(RecentEmojiController.provider)
                      .map((entry) => entry.emoji),
                  "👍",
                  "🤣",
                  "😭",
                  "🤔",
                }.take(4))
                  IconButton(
                    icon: Text(emoji),
                    onPressed: () {
                      Navigator.of(context).pop();
                      sendReaction(emoji);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () {
                    Navigator.of(context).pop();

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => EmojiPicker(
                        allowFreeText: true,
                        onSelection: (emoji) {
                          Navigator.of(context).pop();
                          sendReaction(emoji);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

      if (ref.watch(
        PowerLevelController.provider(
          .new(eventType: .message, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          onTap: () => onRelation(this, .reply),
          child: const ListTile(
            leading: Icon(Icons.reply),
            title: Text("Reply"),
          ),
        ),

      if (content is MessageContent && sender == userId)
        PopupMenuItem(
          onTap: () => onRelation(this, .edit),
          child: const ListTile(leading: Icon(Icons.edit), title: Text("Edit")),
        ),

      if (ref.watch(
        PowerLevelController.provider(
          .state(eventType: .pinnedEvents, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          onTap: () async {
            try {
              final pins = ref.read(
                PinnedIdsController.provider(roomId).notifier,
              );

              if (isPinned) {
                await pins.removePin(eventId);
              } else {
                await pins.addPin(eventId);
              }
            } catch (error, stackTrace) {
              showError(error, stackTrace);
            }
          },
          child: ListTile(
            leading: const Icon(Icons.push_pin),
            title: Text(isPinned ? "Unpin Event" : "Pin Event"),
          ),
        ),

      PopupMenuItem(
        onTap: () async {
          final room = ref.read(
            RoomsController.provider.select((rooms) => rooms[roomId]),
          );
          if (room == null) return;

          final vias = ref.read(ViaController.provider(room));

          await Clipboard.setData(
            ClipboardData(
              text:
                  "matrix:roomid/${room.metadata?.id.substring(1)}/e/$eventId$vias",
            ),
          );
        },
        child: const ListTile(
          leading: Icon(Icons.link),
          title: Text("Copy Link"),
        ),
      ),

      if (content case MessageContent(:final body?))
        PopupMenuItem(
          onTap: () => Clipboard.setData(ClipboardData(text: body)),
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text("Copy Text"),
          ),
        ),

      if (ref.watch(
        PowerLevelController.provider(
          .redaction(targetUser: sender, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          onTap: () => showReasonDialog(
            title: "Delete Message",
            description:
                "Are you sure you want to delete this message? "
                "This cannot be reversed.",
            action: "Delete",
            onConfirm: (reason) => notifier.deleteMessage(this, reason: reason),
          ),
          child: ListTile(
            leading: Icon(Icons.delete, color: danger),
            title: Text("Delete", style: .new(color: danger)),
          ),
        ),

      PopupMenuItem(
        onTap: () => showReasonDialog(
          title: "Report",
          description:
              "Report this this to your server administrators, "
              "who can take action like banning this server or room.",
          action: "Report",
          onConfirm: (reason) => client.reportEvent(
            .new(
              roomId: roomId,
              eventId: eventId,
              reason: reason.isEmpty ? null : reason,
            ),
          ),
        ),
        child: ListTile(
          leading: Icon(Icons.report, color: danger),
          title: Text("Report", style: .new(color: danger)),
        ),
      ),
    ]);
  }
}
