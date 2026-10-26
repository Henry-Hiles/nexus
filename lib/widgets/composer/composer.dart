import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/widgets/emoji_picker.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/adaptive_menu_button.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/attachment.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/controllers/image_picker.dart";
import "package:nexus/helpers/file_dialog_helper.dart";
import "package:image_picker/image_picker.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/image_packs.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/widgets/sticker_picker.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/overlays/tagger_overlay.dart";
import "package:nexus/widgets/composer/paste_files_action.dart";
import "package:pasteboard/pasteboard.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:nexus/widgets/composer/relation_preview.dart";
import "package:nexus/main.dart";

class const Composer(
  final String roomId, {
  required final int? relatedEvent,
  required final RelationType relationType,
  required final VoidCallback onDismiss,
  required final Future<void> Function(
    String text, {
    required bool shouldMention,
    required IList<Tag> tags,
  })
  onSend,
  required final Future<void> Function(String shortcode, PackImage image)
  onSendSticker,
  final FocusNode? node,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = useMemoized(FlutterTaggerController.new);
    final triggerCharacter = useState("");
    final shouldMention = useState(true);
    final query = useState("");
    final canSendStickers =
        ref.watch(
          PowerLevelController.provider(
            .new(eventType: .sticker, roomId: roomId),
          ),
        ) &&
        (ref
                .watch(ImagePacksController.provider(roomId))
                .value
                ?.any((pack) => pack.stickers.isNotEmpty) ??
            false);
    final relatedEvent = this.relatedEvent == null
        ? null
        : ref.watch(
            RoomsController.provider.select((rooms) {
              final event = rooms[roomId]?.events[this.relatedEvent!];
              if (event == null) return null;

              final edited = event.lastEditRowId == 0
                  ? null
                  : rooms[roomId]?.events[event.lastEditRowId];

              return edited == null
                  ? event
                  : event.copyWith(
                      content: edited.content,
                      localContent: edited.localContent,
                    );
            }),
          );

    final textBefore = useState<String?>(null);

    useEffect(() {
      if (relationType == .edit && relatedEvent != null) {
        textBefore.value ??= controller.text;

        final text =
            relatedEvent.localContent?.editSource ??
            switch (relatedEvent.content) {
              TextMessageContent(:final body) => body,
              _ => "",
            };

        controller.value = .new(
          text: text,
          selection: .collapsed(offset: text.length),
        );
      } else if (textBefore.value case final draft?) {
        controller.value = .new(
          text: draft,
          selection: .collapsed(offset: draft.length),
        );
        textBefore.value = null;
      }

      return null;
    }, [relationType, relatedEvent == null]);

    final sinceTypingSent = useMemoized(Stopwatch.new);

    useEffect(() {
      final client = ref.read(ClientController.provider.notifier);

      void stopTyping() {
        if (!sinceTypingSent.isRunning) return;
        sinceTypingSent
          ..stop()
          ..reset();
        client.setTyping(roomId, .zero).ignore();
      }

      void onChanged() {
        final shouldSend =
            ref.read(SettingsController.provider).value?.typingIndicators ==
            .showAndSend;

        if (!shouldSend || controller.text.isEmpty) return stopTyping();

        if (sinceTypingSent.isRunning &&
            sinceTypingSent.elapsed < const .new(seconds: 5)) {
          return;
        }

        sinceTypingSent
          ..reset()
          ..start();
        client.setTyping(roomId, const .new(seconds: 10)).ignore();
      }

      controller.addListener(onChanged);
      return () {
        controller.removeListener(onChanged);
        stopTyping();
      };
    }, [roomId]);

    final attachment = ref.watch(AttachmentController.provider(roomId));

    Future<void> attach(Future<XFile?> pick) async {
      if (await pick case final file?) {
        await ref
            .read(AttachmentController.provider(roomId).notifier)
            .add(file);
      }
    }

    /// Attaches [bytes] as a file called [filename], e.g. for pasted images.
    Future<void> attachBytes(Uint8List bytes, String filename) async {
      // A new directory each time, so files with the same name don't clash
      final directory = await (await getTemporaryDirectory()).createTemp(
        "attachment",
      );
      final file = await File(join(directory.path, filename))
          .writeAsBytes(bytes);

      await ref
          .read(AttachmentController.provider(roomId).notifier)
          .add(.new(file.path));
    }

    /// Attaches the first file on the clipboard, or the image on it if there
    /// are no files. Returns whether there was either, so that text can be
    /// pasted otherwise.
    Future<bool> pasteFiles() async {
      // Only one attachment is supported at a time
      if (attachment != null) return false;

      // Failing to read the clipboard counts as it being empty, so that text
      // can still be pasted
      final files = await Pasteboard.files().onError((_, _) => const []);
      if (files.firstOrNull case final path?) {
        ref
            .read(AttachmentController.provider(roomId).notifier)
            .add(XFile(path))
            .onError(showError);
        return true;
      }

      if (await Pasteboard.image.onError((_, _) => null) case final image?) {
        attachBytes(image, "image.png").onError(showError);
        return true;
      }

      return false;
    }

    void send() {
      if (controller.value.text.isEmpty && attachment == null ||
          attachment != null && attachment.$2 == null) {
        return;
      }
      onSend(
        controller.formattedText,
        shouldMention: shouldMention.value,
        tags: .new(controller.tags),
      );

      onDismiss();
      controller.text = "";
    }

    final style = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: .bold,
    );

    return Padding(
      padding: .all(12),
      child: Column(
        children: [
          if (attachment != null)
            Card(
              margin: .only(bottom: 8),
              child: ListTile(
                leading: attachment.$2 == null
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(),
                      )
                    : Icon(Icons.file_copy),
                title: Text(attachment.$1),
                trailing: IconButton(
                  onPressed: () =>
                      ref.invalidate(AttachmentController.provider(roomId)),
                  icon: Icon(Icons.close),
                ),
              ),
            ),
          ClipRRect(
            borderRadius: .all(.circular(12)),
            child: Column(
              children: [
                RelationPreview(
                  relatedEvent,
                  shouldMention: shouldMention.value,
                  toggleShouldMention: () =>
                      shouldMention.value = !shouldMention.value,
                  relationType: relationType,
                  onDismiss: onDismiss,
                ),
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: .center,
                    children:
                        ref.watch(
                          PowerLevelController.provider(
                            .new(eventType: .message, roomId: roomId),
                          ),
                        )
                        ? [
                            IconButton(
                              onPressed: () => context.showAdaptiveSheet(
                                (context) => EmojiPicker(
                                  roomId: roomId,
                                  onSelection:
                                      (value, {shortcode, description}) {
                                        Navigator.of(context).pop();
                                        if (shortcode == null) {
                                          controller.text += value;
                                        } else {
                                          final text = "${controller.text}:";
                                          controller.value = .new(
                                            text: text,
                                            selection: .collapsed(
                                              offset: text.length,
                                            ),
                                          );
                                          controller.addTag(
                                            id: ImagePack.emojiMarkdown(
                                              shortcode,
                                              value,
                                              description: description,
                                            ),
                                            name: shortcode,
                                          );
                                        }
                                        node?.requestFocus();
                                      },
                                ),
                              ),
                              icon: Icon(Icons.emoji_emotions),
                            ),
                            AdaptiveMenuButton(
                              tooltip: "Add media",
                              enabled: attachment == null,
                              itemBuilder: (context) => [
                                for (final (source, title, icon) in [
                                  if (Platform.isAndroid || Platform.isIOS)
                                    (
                                      ImageSource.camera,
                                      "Camera",
                                      Icons.add_a_photo,
                                    ),
                                  (
                                    ImageSource.gallery,
                                    "Gallery",
                                    Icons.add_photo_alternate,
                                  ),
                                ])
                                  PopupMenuItem(
                                    child: ListTile(
                                      title: Text(title),
                                      leading: Icon(icon),
                                    ),
                                    onTap: () => attach(
                                      source == .gallery
                                          ? ref
                                                .read(FileDialogHelper.provider)
                                                .pickFile(images: true)
                                          : ref
                                                .read(
                                                  ImagePickerController
                                                      .provider,
                                                )
                                                .pickImage(source: source),
                                    ).onError(showError),
                                  ),
                                PopupMenuItem(
                                  onTap: () => attach(
                                    ref
                                        .read(FileDialogHelper.provider)
                                        .pickFile(),
                                  ).onError(showError),
                                  child: ListTile(
                                    title: Text("Files"),
                                    leading: Icon(Icons.attachment),
                                  ),
                                ),
                                if (canSendStickers)
                                  PopupMenuItem(
                                    onTap: () => context.showAdaptiveSheet(
                                      (context) => StickerPicker(
                                        roomId: roomId,
                                        onSelection: (shortcode, image) {
                                          Navigator.of(context).pop();
                                          onSendSticker(shortcode, image);
                                        },
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text("Sticker"),
                                      leading: Icon(Icons.sticky_note_2),
                                    ),
                                  ),
                              ],
                              icon: Icon(Icons.add),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FlutterTagger(
                                triggerStrategy: .eager,
                                // Characters that continue a search, for
                                // e.g. :+1, :custom_emoji or @user.name
                                searchRegex: .new(r"^[\w.+-]*$"),
                                overlay: TaggerOverlay(
                                  query.value,
                                  roomId: roomId,
                                  triggerCharacter: triggerCharacter.value,
                                  addTag: ({required id, required name}) {
                                    controller.addTag(id: id, name: name);
                                    node?.requestFocus();
                                  },
                                ),
                                controller: controller,
                                onSearch: (newQuery, newTriggerCharacter) {
                                  triggerCharacter.value = newTriggerCharacter;
                                  query.value = newQuery;
                                },
                                triggerCharacterAndStyles: {
                                  "@": style,
                                  "#": style,
                                  ":": style,
                                },
                                builder: (context, key) => Focus(
                                  onKeyEvent: (_, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.enter) {
                                      final shiftPressed = HardwareKeyboard
                                          .instance
                                          .isShiftPressed;

                                      if (!shiftPressed) {
                                        send();
                                        return .handled;
                                      }
                                    }

                                    return .ignored;
                                  },
                                  // Overrides the keyboard shortcut for pasting
                                  child: Actions(
                                    actions: {
                                      PasteTextIntent: PasteFilesAction(
                                        pasteFiles,
                                      ),
                                    },
                                    child: TextField(
                                      maxLines: 12,
                                      minLines: 1,
                                      textCapitalization: .sentences,
                                      autofocus:
                                          (Platform.isLinux ||
                                          Platform.isMacOS ||
                                          Platform.isWindows),
                                      decoration: .new(
                                        hintText: "Your message here...",
                                        border: .none,
                                      ),
                                      controller: controller,
                                      key: key,
                                      focusNode: node,
                                      // The toolbar's paste button doesn't use the shortcut's action, so replace it too
                                      contextMenuBuilder: (_, editableText) =>
                                          AdaptiveTextSelectionToolbar.buttonItems(
                                            anchors:
                                                editableText.contextMenuAnchors,
                                            buttonItems: editableText
                                                .contextMenuButtonItems
                                                .map(
                                                  (item) => item.type == .paste
                                                      ? item.copyWith(
                                                          onPressed: () async {
                                                            editableText
                                                                .hideToolbar();
                                                            if (!await pasteFiles()) {
                                                              item.onPressed
                                                                  ?.call();
                                                            }
                                                          },
                                                        )
                                                      : item,
                                                )
                                                .toList(),
                                          ),
                                      // Images pasted from Android keyboards' clipboards are inserted as content
                                      contentInsertionConfiguration: .new(
                                        onContentInserted: (content) {
                                          if (attachment != null) return;

                                          if (content.data case final data?) {
                                            attachBytes(
                                              data,
                                              "image.${content.mimeType.split("/").last}",
                                            ).onError(showError);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  attachment != null && attachment.$2 == null
                                  ? null
                                  : send,
                              icon: Icon(Icons.send),
                              tooltip: "Send message",
                            ),
                          ]
                        : [
                            Expanded(
                              child: Padding(
                                padding: .symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                child: Text(
                                  "You don't have permission to send messages in this room...",
                                ),
                              ),
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
