import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:nexus/controllers/attachment.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/helpers/extensions/get_filename.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/is_media.dart";
import "package:nexus/helpers/extensions/with_latest_edit.dart";
import "package:nexus/models/composer_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/text_command.dart";

class ComposerDraftController(final ComposerParams composer)
    extends Notifier<ComposerDraft> {
  @override
  ComposerDraft build() => const .new();

  BotCommandDraftController get _botCommand =>
      ref.read(BotCommandDraftController.provider(composer).notifier);

  void update(ComposerDraft Function(ComposerDraft draft) update) =>
      state = update(state);

  void relate(int rowId, RelationType type) {
    if (type == .reply) {
      _restoreBeforeEdit();
      state = state.copyWith(relatedEvent: rowId, relationType: .reply);
      return;
    }

    // Keeps the changes made so far
    if (state.isEditing && state.relatedEvent == rowId) return;

    final event = ref
        .read(RoomsController.provider)[composer.roomId]
        ?.withLatestEdit(rowId);
    final content = event?.content;
    // Edit sources start with text commands, like "/me "
    final (:commands, :text) = TextCommand.parse(
      event?.localContent?.editSource ??
          switch (content) {
            TextMessageContent(:final body) ||
            ImageMessageContent(:final body) ||
            VideoMessageContent(:final body) ||
            AudioMessageContent(:final body) ||
            FileMessageContent(:final body) => body,
            _ => "",
          },
    );

    final tagged = _restoreTags(text);
    state = ComposerDraft(
      text: tagged.text,
      tags: tagged.tags,
      textCommands: commands,
      relatedEvent: rowId,
      relationType: .edit,
      beforeEdit:
          state.beforeEdit ??
          (
            draft: state,
            botCommand: ref.read(BotCommandDraftController.provider(composer)),
          ),
    );
    ref
        .read(
          AttachmentController.provider((
            composer: composer,
            editingRowId: rowId,
          )).notifier,
        )
        .set(
          content is MessageContent && content.isMedia
              ? (content.filename ?? content.body ?? "Attachment", content)
              : null,
        );
    _botCommand.clear();
  }

  static final _tagPattern = RegExp(
    r"\[@[^\]]*\]\(matrix:u/([^)\s]+)\)"
    r"|\[#[^\]]*\]\(matrix:roomid/([^)?\s]+)[^)\s]*\)"
    r'|!\[:([^\]\s]+):\]\(mxc://[^)\s]+(?: "(?:[^"\\]|\\.)*")?\)',
  );

  /// Turns the mentions and custom emoji in [text], an edit source, back into
  /// tags, formatted like the composer's tagTextFormatter.
  ({String text, IList<Tag> tags}) _restoreTags(String text) {
    final rooms = ref.read(RoomsController.provider);
    Tag tagOf(Match match) => switch ((match[1], match[2], match[3])) {
      (final userId?, _, _) => .new(
        id: match[0]!,
        text: userId.split(":").first,
        triggerCharacter: "@",
      ),
      (_, final roomId?, _) => .new(
        id: match[0]!,
        text:
            rooms["!$roomId"]?.metadata?.canonicalAlias?.localpart ??
            "!$roomId",
        triggerCharacter: "#",
      ),
      (_, _, final shortcode) => .new(
        id: match[0]!,
        text: shortcode!,
        triggerCharacter: ":",
      ),
    };

    return (
      text: text.replaceAllMapped(_tagPattern, (match) {
        final tag = tagOf(match);
        return "${tag.triggerCharacter}${tag.id}#${tag.text}#";
      }),
      tags: _tagPattern.allMatches(text).map(tagOf).toISet().toIList(),
    );
  }

  void dismiss() {
    if (state.isEditing) return _restoreBeforeEdit();
    state = state.copyWith(relatedEvent: null);
  }

  void _restoreBeforeEdit() {
    if (state.beforeEdit case (:final draft, :final botCommand)) {
      state = draft;
      _botCommand.set(botCommand);
    }
  }

  static final provider =
      NotifierProvider.family<
        ComposerDraftController,
        ComposerDraft,
        ComposerParams
      >(ComposerDraftController.new);
}
