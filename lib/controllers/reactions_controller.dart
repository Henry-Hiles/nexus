import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/configs/reactions_config.dart";
import "package:nexus/models/content/reaction.dart";

class ReactionsController extends AsyncNotifier<IMap<String, IList<String>>> {
  final ReactionsConfig config;
  ReactionsController(this.config);

  @override
  Future<IMap<String, IList<String>>> build() async {
    final eventInfo = ref.watch(
      RoomsController.provider.select((value) {
        final event = value[config.roomId]?.events[config.eventRowId];
        return event == null ? null : (event.eventId, event.reactions);
      }),
    );

    final reactionEvents = eventInfo?.$2.isNotEmpty == true
        ? await ref
              .watch(ClientController.provider.notifier)
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
            .fold<IMap<String, IList<String>>>(.new(), (acc, event) {
              if (event.content case ReactionContent(:final key?)) {
                return acc.update(
                  key,
                  (list) => list.add(event.sender),
                  ifAbsent: () => .new([event.sender]),
                );
              }

              return acc;
            }) ??
        .new();
  }

  static final provider =
      AsyncNotifierProvider.family<
        ReactionsController,
        IMap<String, IList<String>>,
        ReactionsConfig
      >(ReactionsController.new);
}
