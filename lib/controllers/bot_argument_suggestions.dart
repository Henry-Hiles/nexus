import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/controllers/members_by_status.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/controllers/via.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/helpers/extensions/weighted_search.dart";
import "package:nexus/models/bot_argument_suggestion.dart";
import "package:nexus/models/bot_command_draft.dart";
import "package:nexus/models/composer_params.dart";
import "package:nexus/models/content/bot_command_description.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

class BotArgumentSuggestionsController(final ComposerParams composer)
    extends Notifier<IList<BotArgumentSuggestion>> {
  @override
  IList<BotArgumentSuggestion> build() {
    final draft = ref.watch(BotCommandDraftController.provider(composer));
    final (parameter, text) = switch (draft) {
      BotCommandDraft(focusedParameter: final parameter?, :final texts) => (
        parameter,
        texts[parameter.key] ?? "",
      ),
      _ => (null, ""),
    };
    if (parameter == null) return const .empty();

    final schema = parameter.schema;
    final parts = schema is ArraySchema
        ? text.split(BotParameterSchema.separator)
        : [text];
    final query = parts.last.trim().toLowerCase();
    final picked = parts.take(parts.length - 1).toISet();

    final members = schema.allows(.userId)
        ? ref
                  .watch(
                    MembersByStatusController.provider(
                      .new(roomId: composer.roomId, status: .join),
                    ),
                  )
                  .value ??
              const .empty()
        : const ISet<Event>.empty();
    final rooms = schema.allows(.roomId)
        ? ref.watch(RoomsController.provider).values
        : const <Room>[];

    return {
          ...schema.literals.map((literal) => "$literal"),
          if (schema.allows(.boolean)) ...["True", "False"],
        }
        .map((value) => BotArgumentSuggestion(title: value, text: value))
        .followedBy(
          members
              .map(
                (member) => switch (member) {
                  Event(
                    stateKey: final userId?,
                    content: MembershipContent(
                      :final displayName,
                      :final avatarUrl,
                    ),
                  ) =>
                    BotArgumentSuggestion(
                      title: displayName ?? userId.localpart,
                      subtitle: userId,
                      avatar: avatarUrl,
                      text: userId,
                    ),
                  _ => null,
                },
              )
              .nonNulls,
        )
        .followedBy(
          rooms
              .map(
                (room) => switch (room.metadata) {
                  final metadata? => BotArgumentSuggestion(
                    title:
                        metadata.name ?? metadata.canonicalAlias ?? metadata.id,
                    subtitle: metadata.canonicalAlias ?? metadata.id,
                    avatar: metadata.avatar,
                    text: metadata.id,
                    room: room,
                  ),
                  null => null,
                },
              )
              .nonNulls,
        )
        .where((suggestion) => !picked.contains(suggestion.text))
        .search(
          query,
          (suggestion) => [(suggestion.title, 2), (suggestion.subtitle, 1)],
        )
        .take(8)
        .toIList();
  }

  void pick(BotArgumentSuggestion suggestion) => ref
      .read(BotCommandDraftController.provider(composer).notifier)
      .pick(
        suggestion,
        via: switch (suggestion.room) {
          final room? => ref.read(ViaController.provider(room)),
          null => const .empty(),
        },
      );

  bool pickTop() {
    final draft = ref.read(BotCommandDraftController.provider(composer));
    if (state.firstOrNull case final suggestion?
        when draft != null && !draft.arguments.containsKey(draft.focused)) {
      pick(suggestion);
      return true;
    }
    return false;
  }

  static final provider = NotifierProvider.autoDispose
      .family<
        BotArgumentSuggestionsController,
        IList<BotArgumentSuggestion>,
        ComposerParams
      >(BotArgumentSuggestionsController.new);
}
