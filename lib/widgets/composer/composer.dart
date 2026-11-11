import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:collection/collection.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/bot_argument_suggestions.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/controllers/bot_commands.dart";
import "package:nexus/controllers/composer_draft.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/refocus_after_rebuild.dart";
import "package:nexus/helpers/extensions/show_error_snack_bar.dart";
import "package:nexus/helpers/extensions/with_latest_edit.dart";
import "package:nexus/models/bot_command.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/text_command.dart";
import "package:nexus/widgets/composer/bot_command_form.dart";
import "package:nexus/widgets/composer/bot_command_panel.dart";
import "package:nexus/widgets/emoji/emoji_picker.dart";
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
import "package:nexus/widgets/renderers/message_media.dart";
import "package:nexus/helpers/extensions/is_media.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/widgets/emoji/mxc_emoji.dart";
import "package:nexus/widgets/emoji/sticker_picker.dart";
import "package:nexus/widgets/composer/create_poll_sheet.dart";
import "package:nexus/widgets/location/location_picker_sheet.dart";
import "package:nexus/models/location.dart";
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
  final String? threadRoot,
  final FocusNode? node,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ComposerParams composer = (roomId: roomId, threadRoot: threadRoot);
    final draftProvider = ComposerDraftController.provider(composer);
    final draftNotifier = ref.watch(draftProvider.notifier);
    final (
      :relatedEventRowId,
      :relationType,
      :editingEvent,
      :sticker,
      :poll,
      :location,
      :textCommands,
    ) = ref.watch(
      draftProvider.select(
        (draft) => (
          relatedEventRowId: draft.relatedEvent,
          relationType: draft.relationType,
          editingEvent: draft.isEditing ? draft.relatedEvent : null,
          sticker: draft.sticker,
          poll: draft.poll,
          location: draft.location,
          textCommands: draft.textCommands,
        ),
      ),
    );
    final isEditing = editingEvent != null;

    final botCommandProvider = BotCommandDraftController.provider(composer);
    final attachmentProvider = AttachmentController.provider((
      composer: composer,
      editingRowId: editingEvent,
    ));
    final botCommand = ref.watch(botCommandProvider);

    final hasReplacement =
        sticker != null ||
        poll != null ||
        location != null ||
        botCommand != null;

    final controller = useMemoized(() {
      final draft = ref.read(draftProvider);
      final ids = IMap.fromEntries(
        draft.tags
            .map((tag) => MapEntry("${tag.triggerCharacter}${tag.id}#", tag.id))
            .sortedBy<num>((entry) => -entry.key.length),
      );

      return FlutterTaggerController(text: draft.text)..formatTags(
        // Matches tags formatted by tagTextFormatter, like ":id#name#"
        pattern: RegExp(
          ids.isEmpty
              ? "(?!)"
              : "((?:${ids.keys.map(RegExp.escape).join("|")})[^#]*#)",
        ),
        parser: (formatted) {
          final prefix = ids.keys.firstWhere(formatted.startsWith);
          return [
            ids[prefix]!,
            formatted.substring(prefix.length, formatted.length - 1),
          ];
        },
      );
    }, [composer, editingEvent, hasReplacement]);
    useEffect(
      // After the frame, as FlutterTagger and TextField still use it until then
      () =>
          () => WidgetsBinding.instance.addPostFrameCallback(
            (_) => controller.dispose(),
          ),
      [controller],
    );

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
    final relatedEvent = relatedEventRowId == null
        ? null
        : ref.watch(
            RoomsController.provider.select(
              (rooms) => rooms[roomId]?.withLatestEdit(relatedEventRowId),
            ),
          );

    void dismiss() {
      draftNotifier.dismiss();
      // Ending an edit replaces the text field
      if (isEditing && (node?.hasFocus ?? false)) node?.refocusAfterRebuild();
    }

    final sinceTypingSent = useMemoized(Stopwatch.new);
    final client = ref.watch(ClientController.provider.notifier);

    void stopTyping() {
      if (!sinceTypingSent.isRunning) return;
      sinceTypingSent
        ..stop()
        ..reset();
      client.setTyping(roomId, .zero).ignore();
    }

    // Stops typing in the previous room, or the message before an edit
    useEffect(() => stopTyping, [controller]);

    // Called by FlutterTagger for changes once attached, unlike a listener on
    // the controller, which is also told about the draft being restored
    // during the build
    void onFormattedTextChanged(String text) {
      final draft = ref.read(draftProvider);
      if (text == draft.text ||
          (draft.isEditing ? draft.relatedEvent : null) != editingEvent) {
        return;
      }

      draftNotifier.update(
        (draft) => draft.copyWith(text: text, tags: controller.tags.toIList()),
      );

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

    final attachment = ref.watch(attachmentProvider);

    Future<void> attach(Future<XFile?> pick) async {
      if (await pick case final file?) {
        await ref.read(attachmentProvider.notifier).add(file);
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

      await ref.read(attachmentProvider.notifier).add(.new(file.path));
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
            .read(attachmentProvider.notifier)
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

    // Bot commands can't follow text commands, which gomuks sends as text
    final botCommands =
        isEditing ||
            hasReplacement ||
            attachment != null ||
            textCommands.isNotEmpty
        ? const IList<BotCommand>.empty()
        : ref.watch(BotCommandsController.provider(roomId)).value ??
              const .empty();

    final availableTextCommands = hasReplacement || attachment != null
        ? const IList<TextCommand>.empty()
        : TextCommand.values
              .where((command) => !textCommands.contains(command))
              .toIList();

    void setTextCommands(IList<TextCommand> commands) =>
        draftNotifier.update((draft) => draft.copyWith(textCommands: commands));

    void pickTextCommand(TextCommand command) {
      setTextCommands(command.addTo(textCommands));
      controller.text = "";
      node?.requestFocus();
    }

    void removeTextCommand(TextCommand command) {
      setTextCommands(textCommands.remove(command));
      node?.requestFocus();
    }

    /// Turns text commands typed at the start, like "/me ", into chips.
    /// Returns whether there were any.
    bool pickTypedTextCommands(String text) {
      if (availableTextCommands.isEmpty) return false;
      final parsed = TextCommand.parse(text, textCommands);
      if (parsed.text == text) return false;

      setTextCommands(parsed.commands);
      final removed = text.length - parsed.text.length;
      controller.value = .new(
        text: parsed.text,
        selection: .collapsed(
          offset: (controller.selection.baseOffset - removed).clamp(
            0,
            parsed.text.length,
          ),
        ),
      );
      return true;
    }

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

    void pickTypedCommand(String text) {
      if (pickTypedTextCommands(text)) return;
      if (botCommands.any((command) => command.prefix.startsWith(text))) return;
      if (typedBotCommand(text) case final command?) pickBotCommand(command);
    }

    void removeBotCommand({required bool keepText}) {
      // The text field gets a new controller from the draft once it's back
      if (botCommand?.command.prefix case final prefix? when keepText) {
        draftNotifier.update(
          (draft) => draft.copyWith(text: prefix, tags: const .empty()),
        );
      }
      ref.read(botCommandProvider.notifier).clear();
      // The text field replaces the command form
      node?.refocusAfterRebuild();
    }

    void send() {
      if (hasReplacement) {
        if (botCommand != null) {
          if (ref
              .read(
                BotArgumentSuggestionsController.provider(composer).notifier,
              )
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

        if (sticker case (final shortcode, final image)?) {
          onSendSticker(shortcode, image, shouldMention: shouldMention.value);
        } else if (poll case final draft?) {
          onSendPoll(draft, shouldMention: shouldMention.value);
        } else if (location case final draft?) {
          onSendLocation(draft, shouldMention: shouldMention.value);
        } else if (botCommand != null) {
          onSendBotCommand(botCommand);
        }
        dismiss();
        // The draft is kept, so it can still be sent after the replacement
        draftNotifier.update(
          (draft) => draft.copyWith(sticker: null, poll: null, location: null),
        );
        ref.read(botCommandProvider.notifier).clear();
        // Once the text field is back
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => node?.requestFocus(),
        );
        return;
      }

      // In the order the command panel shows them
      if (typedBotCommand(controller.text) case final command?) {
        return pickBotCommand(command);
      }
      if (availableTextCommands.firstWhereOrNull(
            (command) => command.completes(controller.text),
          )
          case final command?) {
        return pickTextCommand(command);
      }
      if (botCommands.firstWhereOrNull(
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
        "${TextCommand.prefixOf(textCommands)}${controller.formattedText}",
        shouldMention: shouldMention.value,
        tags: .new(controller.tags),
      );

      // Before dismissing, which restores the draft from before an edit
      controller.text = "";
      setTextCommands(const .empty());
      dismiss();
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

    KeyEventResult onTextFieldKeyEvent(FocusNode node, KeyEvent event) {
      if (textCommands.lastOrNull case final command?
          when event is KeyDownEvent &&
              event.logicalKey == .backspace &&
              controller.selection.isCollapsed &&
              controller.selection.baseOffset == 0) {
        setTextCommands(textCommands.removeLast());
        if (controller.text.isEmpty) {
          controller.value = .new(
            text: command.prefix,
            selection: .collapsed(offset: command.prefix.length),
          );
        }
        return .handled;
      }

      return sendOnEnter(node, event);
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
              child: Column(
                children: [
                  ListTile(
                    leading: switch (attachment.$2) {
                      null => SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(),
                      ),
                      ImageMessageContent() => Icon(Icons.image),
                      VideoMessageContent() => Icon(Icons.movie),
                      AudioMessageContent() => Icon(Icons.audiotrack),
                      _ => Icon(Icons.file_copy),
                    },
                    title: Text(attachment.$1),
                    trailing: IconButton(
                      onPressed: () => ref.invalidate(attachmentProvider),
                      icon: Icon(Icons.close),
                    ),
                  ),
                  AnimatedSize(
                    duration: Durations.short4,
                    alignment: .topCenter,
                    child: switch (attachment.$2) {
                      final content?
                          when content is! FileMessageContent &&
                              content.isMedia =>
                        Padding(
                          padding: EdgeInsets.all(12).copyWith(top: 0),
                          child: Align(
                            alignment: .centerLeft,
                            child: ConstrainedBox(
                              constraints: .loose(.square(300)),
                              child: MessageMedia(content),
                            ),
                          ),
                        ),
                      _ => SizedBox(width: .infinity),
                    },
                  ),
                ],
              ),
            ),
          AnimatedSize(
            duration: Durations.short4,
            alignment: .bottomCenter,
            child: BotCommandPanel(
              composer,
              commands: botCommands,
              textCommands: availableTextCommands,
              controller: controller,
              onPick: pickBotCommand,
              onPickText: pickTextCommand,
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
                  onDismiss: dismiss,
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
                                          draftNotifier.update(
                                            (draft) => draft.copyWith(
                                              sticker: (shortcode, image),
                                            ),
                                          );
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
                                          draftNotifier.update(
                                            (draft) =>
                                                draft.copyWith(poll: created),
                                          );
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
                                        draftNotifier.update(
                                          (draft) =>
                                              draft.copyWith(location: picked),
                                        );
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
                                  sticker,
                                  poll,
                                  location,
                                  botCommand,
                                )) {
                                  (_, final draft?, _, _) =>
                                    ComposerReplacement(
                                      removeTooltip: "Remove poll",
                                      onRemove: () {
                                        draftNotifier.update(
                                          (draft) => draft.copyWith(poll: null),
                                        );
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
                                        draftNotifier.update(
                                          (draft) =>
                                              draft.copyWith(sticker: null),
                                        );
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
                                        draftNotifier.update(
                                          (draft) =>
                                              draft.copyWith(location: null),
                                        );
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
                                    // Attaches each new controller
                                    key: ObjectKey(controller),
                                    triggerStrategy: .eager,
                                    onFormattedTextChanged:
                                        onFormattedTextChanged,
                                    // Keeps the trigger character, so tags
                                    // can be restored from drafts
                                    tagTextFormatter: (
                                      id,
                                      tag,
                                      triggerCharacter,
                                    ) => "$triggerCharacter$id#$tag#",
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
                                      onKeyEvent: onTextFieldKeyEvent,
                                      // Overrides the keyboard shortcut for pasting
                                      child: Actions(
                                        actions: {
                                          PasteTextIntent: PasteFilesAction(
                                            pasteFiles,
                                          ),
                                        },
                                        child: Row(
                                          spacing: 4,
                                          children: [
                                            ...textCommands.map(
                                              (command) => InputChip(
                                                label: Text(command.prefix),
                                                tooltip: command.description,
                                                visualDensity: .compact,
                                                materialTapTargetSize:
                                                    .shrinkWrap,
                                                onDeleted: () =>
                                                    removeTextCommand(command),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextField(
                                                maxLines: 12,
                                                minLines: 1,
                                                textCapitalization: .sentences,
                                                onChanged: pickTypedCommand,
                                                autofocus:
                                                    (Platform.isLinux ||
                                                    Platform.isMacOS ||
                                                    Platform.isWindows),
                                                decoration: .new(
                                                  hintText:
                                                      "Your message here...",
                                                  border: .none,
                                                ),
                                                controller: controller,
                                                key: key,
                                                focusNode: node,
                                                // The toolbar's paste button doesn't use the shortcut's action, so replace it too
                                                contextMenuBuilder:
                                                    (
                                                      _,
                                                      editableText,
                                                    ) => AdaptiveTextSelectionToolbar.buttonItems(
                                                      anchors: editableText
                                                          .contextMenuAnchors,
                                                      buttonItems: editableText
                                                          .contextMenuButtonItems
                                                          .map(
                                                            (item) =>
                                                                item.type ==
                                                                    .paste
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
                                                    if (attachment != null) {
                                                      return;
                                                    }

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
                                          ],
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
