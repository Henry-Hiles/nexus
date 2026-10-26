import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/sheet_layout.dart";
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
import "package:nexus/helpers/extensions/event_id_is_fake.dart";
import "package:nexus/helpers/extensions/is_desktop.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/emoji_picker.dart";
import "package:nexus/widgets/mxc_emoji.dart";
import "package:nexus/main.dart";

extension BuildEventOptions on Event {
  IList<PopupMenuEntry> buildEventOptions({
    required BuildContext context,
    required WidgetRef ref,
    required String roomId,
    required String userId,
    required void Function(int, RelationType) onRelation,
  }) {
    final theme = Theme.of(context);
    final danger = theme.colorScheme.error;
    final isDesktop = context.isDesktop;

    final notifier = RoomChatController.provider((
      roomId: roomId,
      contextualEvent: null,
    )).notifier;

    final isPinned = ref
        .read(PinnedIdsController.provider(roomId))
        .contains(eventId);

    void showReasonSheet({
      required String title,
      required String description,
      required String action,
      required Future<void> Function(String reason) onConfirm,
    }) {
      context.showAdaptiveSheet(
        (context) => HookBuilder(
          builder: (context) {
            final reasonController = useTextEditingController();

            return SheetLayout(
              title: Text(title),
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
              children: [
                Text(description),
                TextField(
                  controller: reasonController,
                  textCapitalization: .sentences,
                  decoration: .new(labelText: "Reason (optional)"),
                ),
              ],
            );
          },
        ),
      );
    }

    return .new([
      if (ref.read(
        PowerLevelController.provider(
          .new(eventType: .reaction, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          enabled: false,
          child: IconTheme(
            data: theme.iconTheme,
            child: Row(
              mainAxisAlignment: isDesktop ? .center : .spaceEvenly,
              children: [
                ...{
                      // Custom emoji are sent without their shortcode, as only
                      // their mxc URL is recorded
                      ...ref
                          .read(RecentEmojiController.provider)
                          .map((entry) => entry.emoji),
                      "👍",
                      "🤣",
                      "😭",
                      "🤔",
                      "❤️",
                    }
                    .take(isDesktop ? 3 : 5)
                    .map(
                      (emoji) => IconButton(
                        icon: emoji.startsWith("mxc://")
                            ? SizedBox.square(
                                dimension: isDesktop ? 18 : 24,
                                child: MxcEmoji(Uri.parse(emoji)),
                              )
                            : Text(
                                emoji,
                                style: .new(fontSize: isDesktop ? null : 18),
                              ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await ref
                              .read(notifier)
                              .sendReaction(emoji, this)
                              .onError(showError);

                          await ref
                              .read(RecentEmojiController.provider.notifier)
                              .add(emoji)
                              .onError(showError);
                        },
                      ),
                    ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () {
                    Navigator.of(context).pop();

                    context.showAdaptiveSheet(
                      (context) => EmojiPicker(
                        roomId: roomId,
                        allowFreeText: true,
                        onSelection: (emoji, {shortcode, description}) {
                          Navigator.of(context).pop();
                          ref
                              .read(notifier)
                              .sendReaction(emoji, this, shortcode: shortcode)
                              .onError(showError);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

      if (ref.read(
        PowerLevelController.provider(
          .new(eventType: .message, roomId: roomId),
        ),
      ))
        PopupMenuItem(
          onTap: () => onRelation(rowId, .reply),
          child: const ListTile(
            leading: Icon(Icons.reply),
            title: Text("Reply"),
          ),
        ),

      if (content is MessageContent && sender == userId)
        PopupMenuItem(
          onTap: () => onRelation(rowId, .edit),
          child: const ListTile(leading: Icon(Icons.edit), title: Text("Edit")),
        ),

      if (ref.read(
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
                  "matrix:roomid/${room.metadata?.id.substring(1)}/e/${eventId.substring(1)}$vias",
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

      if (ref.read(
            PowerLevelController.provider(
              .redaction(targetUser: sender, roomId: roomId),
            ),
          ) &&
          !eventId.isFake)
        PopupMenuItem(
          onTap: () => showReasonSheet(
            title: "Delete Message",
            description:
                "Are you sure you want to delete this message? "
                "This cannot be reversed.",
            action: "Delete",
            onConfirm: (reason) =>
                ref.read(notifier).deleteMessage(this, reason: reason),
          ),
          child: ListTile(
            leading: Icon(Icons.delete, color: danger),
            title: Text("Delete", style: .new(color: danger)),
          ),
        ),

      if (eventId.isFake)
        PopupMenuItem(
          onTap: () => ref.read(notifier).hideClientSticky(rowId),
          child: ListTile(
            leading: Icon(Icons.delete, color: danger),
            title: Text("Hide", style: .new(color: danger)),
          ),
        ),

      PopupMenuItem(
        onTap: () => showReasonSheet(
          title: "Report",
          description:
              "Report this event to your server administrators, "
              "who can take action like banning this server or room.",
          action: "Report",
          onConfirm: (reason) => ref
              .read(ClientController.provider.notifier)
              .reportEvent(
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
