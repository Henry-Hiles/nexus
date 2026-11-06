import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fluttertagger/fluttertagger.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/content/message.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/relation_type.dart";
import "package:nexus/models/text_command.dart";

part "composer_draft.freezed.dart";

@Freezed(toJson: false, fromJson: false)
class const ComposerDraft({
  // Formatted like ":id#name#", see the composer's tagTextFormatter
  final String text = "",
  final IList<Tag> tags = const .empty(),
  final IList<TextCommand> textCommands = const .empty(),
  final int? relatedEvent,
  final RelationType relationType = .reply,

  // Replace the text field until they are sent or removed
  final (String, PackImage)? sticker,
  final PollStart? poll,
  final LocationMessageContent? location,

  // The draft from before an edit, restored once it is sent or cancelled
  final ({ComposerDraft draft, BotCommandDraft? botCommand})? beforeEdit,
}) with _$ComposerDraft {
  bool get isEditing => beforeEdit != null;
}
