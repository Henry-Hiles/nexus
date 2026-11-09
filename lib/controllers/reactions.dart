import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/emoji_shortcodes.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/configs/event.dart";
import "package:nexus/models/content/reaction.dart";
import "package:nexus/models/reaction_group.dart";

class ReactionsController(final EventConfig config)
    extends AsyncNotifier<IMap<String, ReactionGroup>> {
  @override
  Future<IMap<String, ReactionGroup>> build() async {
    final unicodeShortcodes = ref.watch(EmojiShortcodesController.provider);

    final eventInfo = ref.watch(
      RoomsController.provider.select((value) {
        final event = value[config.roomId]?.events[config.eventRowId];
        return event == null ? null : (event.eventId, event.reactions);
      }),
    );

    final reactionEvents = eventInfo?.$2.isNotEmpty == true
        ? await ref
              .read(ClientController.provider.notifier)
              .getRelatedEvents(
                .new(
                  roomId: config.roomId,
                  eventId: eventInfo!.$1,
                  relationType: "m.annotation",
                ),
              )
        : null;

    return reactionEvents
            ?.where((event) => event.redactedBy == null)
            .fold<IMap<String, ReactionGroup>>(.new(), (acc, event) {
              if (event.content case ReactionContent(
                :final key?,
                :final shortcode,
              )) {
                return acc.update(
                  key,
                  (group) => group.copyWith(
                    senders: group.senders.add(event.sender),
                    shortcode: group.shortcode ?? shortcode,
                  ),
                  ifAbsent: () => .new(
                    senders: .new([event.sender]),
                    shortcode:
                        shortcode ??
                        unicodeShortcodes[EmojiShortcodesController.normalize(
                          key,
                        )],
                  ),
                );
              }

              return acc;
            }) ??
        .new();
  }

  static final provider =
      AsyncNotifierProvider.family<
        ReactionsController,
        IMap<String, ReactionGroup>,
        EventConfig
      >(ReactionsController.new);
}
