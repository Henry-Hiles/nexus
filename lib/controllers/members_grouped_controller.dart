import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_by_status_controller.dart";
import "package:nexus/controllers/room_creators_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/configs/members_by_status_config.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/event.dart";

class MembersGroupedController
    extends AsyncNotifier<IList<MapEntry<int?, ISet<Event>>>> {
  final MembersByStatusConfig config;
  MembersGroupedController(this.config);

  @override
  Future<IList<MapEntry<int?, ISet<Event>>>> build() async {
    final room = ref.watch(
      RoomsController.provider.select((value) => value[config.roomId]),
    );

    final roomCreators = room == null
        ? null
        : ref.watch((RoomCreatorsController.provider(room)));

    final powerLevelsRowId = room?.state[EventType.powerLevels.type]?[""];
    final powerLevelsEvent = powerLevelsRowId == null
        ? null
        : room?.events[powerLevelsRowId];

    final content = switch (powerLevelsEvent?.content) {
      PowerLevelsContent content => content,
      _ => PowerLevelsContent(),
    };

    final members = await ref.watch(
      MembersByStatusController.provider(config).future,
    );

    return members
        .fold<IMap<int?, ISet<Event>>>(.new(), (result, event) {
          final groupKey = roomCreators?.contains(event.stateKey!) == true
              ? null
              : content.users[event.stateKey!] ?? content.usersDefault;

          return result.update(
            groupKey,
            (value) => value.add(event),
            ifAbsent: () => .new({event}),
          );
        })
        .toEntryIList(
          compare: (a, b) =>
              (b?.key ?? double.infinity).compareTo(a?.key ?? double.infinity),
        );
  }

  static final provider =
      AsyncNotifierProvider.family<
        MembersGroupedController,
        IList<MapEntry<int?, ISet<Event>>>,
        MembersByStatusConfig
      >(MembersGroupedController.new);
}
