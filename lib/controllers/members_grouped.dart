import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_by_status.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/models/configs/members_by_status.dart";
import "package:nexus/models/event.dart";

class MembersGroupedController(final MembersByStatusConfig config)
    extends AsyncNotifier<IList<MapEntry<int?, ISet<Event>>>> {
  @override
  Future<IList<MapEntry<int?, ISet<Event>>>> build() async {
    final powerLevels = ref.watch(
      RoomPowerLevelsController.provider(config.roomId),
    );

    final members = await ref.watch(
      MembersByStatusController.provider(config).future,
    );

    return members
        .fold<IMap<int?, ISet<Event>>>(.new(), (result, event) {
          final groupKey = powerLevels.creators.contains(event.stateKey!)
              ? null
              : powerLevels.levelOf(event.stateKey!).toInt();

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
