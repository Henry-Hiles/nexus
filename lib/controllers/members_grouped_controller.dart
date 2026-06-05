import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_by_status_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/configs/members_by_status_config.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/event.dart";

class MembersGroupedController extends AsyncNotifier<IMap<int, ISet<Event>>> {
  final MembersByStatusConfig config;
  MembersGroupedController(this.config);

  @override
  Future<IMap<int, ISet<Event>>> build() async {
    final event = ref.watch(
      RoomsController.provider.select((value) {
        final room = value[config.roomId];
        final eventRowId = room?.state[EventType.powerLevels.type]?[""];
        return eventRowId == null ? null : room?.events[eventRowId];
      }),
    );

    final content = event?.content is PowerLevelsContent
        ? event!.content as PowerLevelsContent
        : PowerLevelsContent();

    final members = await ref.watch(
      MembersByStatusController.provider(config).future,
    );

    return members.fold<IMap<int, ISet<Event>>>(.new(), (result, event) {
      final groupKey = content.users[event.stateKey!] ?? content.usersDefault;

      return result.update(
        groupKey,
        (value) => value.add(event),
        ifAbsent: () => .new({event}),
      );
    });
  }

  static final provider =
      AsyncNotifierProvider.family<
        MembersGroupedController,
        IMap<int, ISet<Event>>,
        MembersByStatusConfig
      >(MembersGroupedController.new);
}
