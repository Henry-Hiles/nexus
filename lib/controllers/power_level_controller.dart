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

    int powerLevelOf(String userId) => users.containsKey(userId)
        ? (users[userId] as int)
        : (event.content["users_default"] as int? ?? 0);

    final userLevel = powerLevelOf(user);
    final targetLevel = config.targetUser != null
        ? powerLevelOf(config.targetUser!)
        : null;

    if (config.action != null) {
      return switch (config.action!) {
        MembershipAction.invite =>
          userLevel >= (event.content["invite"] as int? ?? 0),

        MembershipAction.kick =>
          targetLevel != null &&
              userLevel >= (event.content["kick"] as int? ?? 50) &&
              userLevel > targetLevel,

        MembershipAction.ban =>
          targetLevel != null &&
              userLevel >= (event.content["ban"] as int? ?? 50) &&
              userLevel > targetLevel,

        MembershipAction.unban =>
          userLevel >= (event.content["ban"] as int? ?? 50),
      };
    }

    if (config.eventType == "m.room.redaction") {
      return userLevel >= (event.content["redact"] as int? ?? 50);
    }

    final requiredLevel = events.containsKey(config.eventType)
        ? (events[config.eventType] as int)
        : (config.isStateEvent
              ? (event.content["state_default"] as int? ?? 50)
              : (event.content["events_default"] as int? ?? 0));

    return userLevel >= requiredLevel;
  }

  static final provider = NotifierProvider.autoDispose
      .family<PowerLevelController, bool, PowerLevelConfig>(
        PowerLevelController.new,
      );
}
