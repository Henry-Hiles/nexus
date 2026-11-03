import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:collection/collection.dart";
import "package:nexus/controllers/bot_argument_suggestions.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/controllers/bot_commands.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/show_error_snack_bar.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/widgets/composer/bot_command_form.dart";
import "package:nexus/widgets/composer/bot_command_panel.dart";
import "package:nexus/widgets/emoji_picker.dart";
import "package:nexus/helpers/extensions/get_filename.dart";
import "package:nexus/helpers/extensions/is_media.dart";
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
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/widgets/mxc_emoji.dart";
import "package:nexus/widgets/sticker_picker.dart";
import "package:nexus/widgets/create_poll_sheet.dart";
import "package:nexus/widgets/location_picker_sheet.dart";
import "package:nexus/models/location.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/widgets/composer/overlays/tagger_overlay.dart";
import "package:nexus/widgets/composer/paste_files_action.dart";
import "package:pasteboard/pasteboard.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:nexus/widgets/composer/relation_preview.dart";
import "package:nexus/widgets/composer/composer_replacement.dart";
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
  required final Future<void> Function(
    String shortcode,
    PackImage image, {
    required bool shouldMention,
  })
  onSendSticker,
  required final Future<void> Function(
    PollStart poll, {
    required bool shouldMention,
  })
  onSendPoll,
  required final Future<void> Function(
    LocationMessageContent location, {
    required bool shouldMention,
  })
  onSendLocation,
  required final Future<void> Function(BotCommandDraft draft) onSendBotCommand,
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
    final canSendPolls = ref.watch(
      PowerLevelController.provider(
        .new(eventType: .pollStart, roomId: roomId),
      ),
    );
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
    // Wrapped, since no attachment is a draft too
    final attachmentBefore = useState<((String, MessageContent?)?,)?>(null);

    /// The sticker to send, which replaces the text field until it is sent or
    /// removed, as stickers can't have a caption
    final sticker = useState<(String, PackImage)?>(null);

    final poll = useState<PollStart?>(null);
    final location = useState<LocationMessageContent?>(null);
    final botCommandProvider = BotCommandDraftController.provider(roomId);
    final botCommand = ref.watch(botCommandProvider);
    useEffect(() {
      sticker.value = null;
      poll.value = null;
      location.value = null;
      return null;
    }, [roomId]);

    final hasReplacement =
        sticker.value != null ||
        poll.value != null ||
        location.value != null ||
        botCommand != null;

    // The relation type stays as edit after cancelling an edit
    final isEditing = relationType == .edit && relatedEvent != null;

    useEffect(() {
      final attachmentProvider = AttachmentController.provider(roomId);

      if (relationType == .edit && relatedEvent != null) {
        textBefore.value ??= controller.text;
        attachmentBefore.value ??= (ref.read(attachmentProvider),);
        sticker.value = null;
        poll.value = null;
        location.value = null;
        Future.microtask(ref.read(botCommandProvider.notifier).clear);

        final content = relatedEvent.content;
        final text =
            relatedEvent.localContent?.editSource ??
            switch (content) {
              TextMessageContent(:final body) ||
              ImageMessageContent(:final body) ||
              VideoMessageContent(:final body) ||
              AudioMessageContent(:final body) ||
              FileMessageContent(:final body) => body,
              _ => "",
            };

        controller.value = .new(
          text: text,
          selection: .collapsed(offset: text.length),
        );

        Future.microtask(
          () => ref
              .read(attachmentProvider.notifier)
              .set(
                content is MessageContent && content.isMedia
                    ? (
                        content.filename ?? content.body ?? "Attachment",
                        content,
                      )
                    : null,
              ),
        );
      } else {
        if (textBefore.value case final draft?) {
          controller.value = .new(
            text: draft,
            selection: .collapsed(offset: draft.length),
          );
          textBefore.value = null;
        }

        if (attachmentBefore.value case (final draft,)) {
          Future.microtask(
            () => ref.read(attachmentProvider.notifier).set(draft),
          );
          attachmentBefore.value = null;
        }
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

    final botCommands = isEditing || hasReplacement || attachment != null
        ? const IList<BotCommand>.empty()
        : ref.watch(BotCommandsController.provider(roomId));

    void pickBotCommand(BotCommand command) {
      ref
          .read(botCommandProvider.notifier)
          .start(command, text: command.argumentsIn(controller.text) ?? "");
      controller.text = "";
    }

    BotCommand? typedBotCommand(String text) => switch (botCommands
        .where((command) => command.argumentsIn(text) != null)
        .sortedBy<num>((command) => -command.prefix.length)) {
      [final command, final other, ...] when command.prefix == other.prefix =>
        null,
      [final command, ...] => command,
      [] => null,
    };

    void pickTypedBotCommand(String text) {
      if (botCommands.any((command) => command.prefix.startsWith(text))) return;
      if (typedBotCommand(text) case final command?) pickBotCommand(command);
    }

    void removeBotCommand({required bool keepText}) {
      if (botCommand?.command.prefix case final prefix? when keepText) {
        controller.value = .new(
          text: prefix,
          selection: .collapsed(offset: prefix.length),
        );
      }
      ref.read(botCommandProvider.notifier).clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => node?.requestFocus());
    }

    void send() {
      if (hasReplacement) {
        if (botCommand != null) {
          if (ref
              .read(BotArgumentSuggestionsController.provider(roomId).notifier)
              .pickTop()) {
            return;
          }
          if (botCommand.missing.firstOrNull case final next?
              when next.key != botCommand.focused &&
                  !botCommand.errors.containsKey(botCommand.focused)) {
            ref.read(botCommandProvider.notifier).focus(next.key);
            return;
          }
          if (botCommand.problem case final problem?) {
            ScaffoldMessenger.of(context).showErrorSnackBar(problem);
            ref.read(botCommandProvider.notifier).focusNext();
            return;
          }
        }

        if (sticker.value case (final shortcode, final image)?) {
          onSendSticker(shortcode, image, shouldMention: shouldMention.value);
        } else if (poll.value case final draft?) {
          onSendPoll(draft, shouldMention: shouldMention.value);
        } else if (location.value case final draft?) {
          onSendLocation(draft, shouldMention: shouldMention.value);
        } else if (botCommand != null) {
          onSendBotCommand(botCommand);
        }
        onDismiss();
        // The draft is kept, so it can still be sent after the replacement
        sticker.value = null;
        poll.value = null;
        location.value = null;
        ref.read(botCommandProvider.notifier).clear();
        // Once the text field is back
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => node?.requestFocus(),
        );
        return;
      }

      if (typedBotCommand(controller.text) ??
              botCommands.firstWhereOrNull(
                (command) => command.completes(controller.text),
              )
          case final command?) {
        return pickBotCommand(command);
      }

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

    KeyEventResult sendOnEnter(FocusNode _, KeyEvent event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        send();
        return .handled;
      }

      return .ignored;
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
          AnimatedSize(
            duration: Durations.short4,
            alignment: .bottomCenter,
            child: BotCommandPanel(
              roomId,
              commands: botCommands,
              controller: controller,
              onPick: pickBotCommand,
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
                              onPressed: hasReplacement
                                  ? null
                                  : () => context.showAdaptiveSheet(
                                      (context) => EmojiPicker(
                                        roomId: roomId,
                                        onSelection:
                                            (value, {shortcode, description}) {
                                              Navigator.of(context).pop();
                                              if (shortcode == null) {
                                                controller.text += value;
                                              } else {
                                                final text =
                                                    "${controller.text}:";
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
                              enabled: attachment == null && !hasReplacement,
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
                                    // Stickers can't replace messages
                                    enabled: !isEditing,
                                    onTap: () => context.showAdaptiveSheet(
                                      (context) => StickerPicker(
                                        roomId: roomId,
                                        onSelection: (shortcode, image) {
                                          Navigator.of(context).pop();
                                          sticker.value = (shortcode, image);
                                        },
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text("Sticker"),
                                      leading: Icon(Icons.sticky_note_2),
                                    ),
                                  ),
                                if (canSendPolls)
                                  PopupMenuItem(
                                    enabled: !isEditing,
                                    onTap: () => context.showAdaptiveSheet(
                                      (context) => CreatePollSheet(
                                        onCreate: (created) {
                                          Navigator.of(context).pop();
                                          poll.value = created;
                                        },
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text("Poll"),
                                      leading: Icon(Icons.poll),
                                    ),
                                  ),
                                PopupMenuItem(
                                  enabled: !isEditing,
                                  onTap: () => context.showAdaptiveSheet(
                                    enableDrag: false,
                                    (context) => LocationPickerSheet(
                                      onPick: (picked) {
                                        Navigator.of(context).pop();
                                        location.value = picked;
                                      },
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text("Location"),
                                    leading: Icon(Icons.location_on),
                                  ),
                                ),
                              ],
                              icon: Icon(Icons.add),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: AnimatedSize(
                                duration: Durations.short4,
                                alignment: .bottomCenter,
                                child: switch ((
                                  sticker.value,
                                  poll.value,
                                  location.value,
                                  botCommand,
                                )) {
                                  (_, final draft?, _, _) =>
                                    ComposerReplacement(
                                      removeTooltip: "Remove poll",
                                      onRemove: () {
                                        poll.value = null;
                                        node?.requestFocus();
                                      },
                                      onKeyEvent: sendOnEnter,
                                      ListTile(
                                        leading: Icon(
                                          Icons.poll,
                                          color: theme.colorScheme.primary,
                                        ),
                                        title: Text(draft.question),
                                        subtitle: Text(
                                          draft.answers
                                              .map((answer) => answer.text)
                                              .join(" · "),
                                          maxLines: 1,
                                          overflow: .ellipsis,
                                        ),
                                      ),
                                    ),
                                  ((final shortcode, final image)?, _, _, _) =>
                                    ComposerReplacement(
                                      removeTooltip: "Remove sticker",
                                      onRemove: () {
                                        sticker.value = null;
                                        node?.requestFocus();
                                      },
                                      onKeyEvent: sendOnEnter,
                                      Align(
                                        alignment: .centerLeft,
                                        child: ConstrainedBox(
                                          constraints: .loose(.square(128)),
                                          child: MxcEmoji(
                                            image.url,
                                            label: image.body ?? shortcode,
                                          ),
                                        ),
                                      ),
                                    ),
                                  (_, _, final draft?, _) =>
                                    ComposerReplacement(
                                      removeTooltip: "Remove location",
                                      onRemove: () {
                                        location.value = null;
                                        node?.requestFocus();
                                      },
                                      onKeyEvent: sendOnEnter,
                                      ListTile(
                                        leading: Icon(
                                          draft.assetType == .pin
                                              ? Icons.location_pin
                                              : Icons.my_location,
                                          color: theme.colorScheme.primary,
                                        ),
                                        title: Text(
                                          draft.description ??
                                              (draft.assetType == .pin
                                                  ? "Location"
                                                  : "My location"),
                                        ),
                                        subtitle: Text(
                                          draft.point?.formatted ??
                                              draft.geoUri.toString(),
                                          maxLines: 1,
                                          overflow: .ellipsis,
                                        ),
                                      ),
                                    ),
                                  (_, _, _, final draft?) =>
                                    ComposerReplacement(
                                      removeTooltip: "Remove command",
                                      onRemove: () =>
                                          removeBotCommand(keepText: false),
                                      onKeyEvent: sendOnEnter,
                                      BotCommandForm(
                                        draft,
                                        key: ValueKey(draft.command),
                                        onSubmit: send,
                                        onRemove: () =>
                                            removeBotCommand(keepText: true),
                                      ),
                                    ),
                                  (null, null, null, null) => FlutterTagger(
                                    triggerStrategy: .eager,
                                    // Characters that continue a search, for
                                    // e.g. :+1, :custom_emoji or @user:server
                                    searchRegex: .new(r"^[\w.:+-]*$"),
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
                                      triggerCharacter.value =
                                          newTriggerCharacter;
                                      query.value = newQuery;
                                    },
                                    triggerCharacterAndStyles: {
                                      "@": style,
                                      "#": style,
                                      ":": style,
                                    },
                                    builder: (context, key) => Focus(
                                      onKeyEvent: sendOnEnter,
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
                                          onChanged: pickTypedBotCommand,
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
                                                anchors: editableText
                                                    .contextMenuAnchors,
                                                buttonItems: editableText
                                                    .contextMenuButtonItems
                                                    .map(
                                                      (item) =>
                                                          item.type == .paste
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

                                              if (content.data
                                                  case final data?) {
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
                                },
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
