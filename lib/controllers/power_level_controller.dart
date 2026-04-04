import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/selected_room_controller.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/requests/membership_action.dart";

class PowerLevelController extends Notifier<bool> {
  final PowerLevelConfig config;
  PowerLevelController(this.config);

  @override
  bool build() {
    final room = ref.watch(SelectedRoomController.provider);
    final event = room?.events.firstWhereOrNull(
      (event) => event.rowId == room.state["m.room.power_levels"]?[""],
    );
    final user = ref.watch(ClientStateController.provider)?.userId;
    if (event == null || user == null) return false;

    final users = (event.content["users"] as Map<String, dynamic>? ?? {});
    final events = (event.content["events"] as Map<String, dynamic>? ?? {});

    final userLevel = users.containsKey(user)
        ? (users[user] as int)
        : (event.content["users_default"] as int? ?? 0);

    final requiredLevel = switch (config.action) {
      MembershipAction.ban ||
      MembershipAction.unban => (event.content["ban"] as int? ?? 50),
      MembershipAction.kick => (event.content["kick"] as int? ?? 50),
      MembershipAction.invite => (event.content["invite"] as int? ?? 0),
      null =>
        events.containsKey(config.eventType)
            ? (events[config.eventType] as int)
            : (config.isStateEvent
                  ? (event.content["state_default"] as int? ?? 50)
                  : (event.content["events_default"] as int? ?? 0)),
    };

    return userLevel >= requiredLevel;
  }

  static final provider = NotifierProvider.autoDispose
      .family<PowerLevelController, bool, PowerLevelConfig>(
        PowerLevelController.new,
      );
}
