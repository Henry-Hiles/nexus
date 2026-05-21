import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/rooms_controller.dart";
import "package:nexus/models/configs/power_level_config.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/requests/membership_action.dart";

class PowerLevelController extends Notifier<bool> {
  final PowerLevelConfig config;
  PowerLevelController(this.config);

  @override
  bool build() {
    if (config case EventPowerLevelConfig(:final eventType)) {
      assert(
        eventType != EventType.redaction,
        "Checking power level for a redaction should use [PowerLevelConfig.redaction].",
      );
    }

    final room = ref.watch(
      RoomsController.provider.select((value) => value[config.roomId]),
    );

    final eventRowId = room?.state[EventType.powerLevels.type]?[""];

    final event = eventRowId == null ? null : room?.events[eventRowId];
    final content = event?.content is PowerLevelsContent
        ? event!.content
        : PowerLevelsContent();
    final user = ref.watch(
      ClientStateController.provider.select((value) => value?.userId),
    );
    if (user == null || content is! PowerLevelsContent) return false;

    int powerLevelOf(String userId) =>
        content.users[userId] ?? content.usersDefault;

    final userLevel = powerLevelOf(user);

    return switch (config) {
      EventPowerLevelConfig(:final eventType) =>
        userLevel >= (content.events[eventType.type] ?? content.eventsDefault),

      MembershipActionPowerLevelConfig(:final action, :final targetUser) =>
        switch (action) {
          MembershipAction.invite => userLevel >= content.invite,

          MembershipAction.kick =>
            userLevel >= content.kick && userLevel > powerLevelOf(targetUser),

          MembershipAction.ban =>
            userLevel >= content.ban && userLevel > powerLevelOf(targetUser),

          MembershipAction.unban => userLevel >= content.ban,
        },

      StatePowerLevelConfig(:final eventType) =>
        userLevel >= (content.events[eventType.type] ?? content.stateDefault),

      RedactionPowerLevelConfig(:final targetUser) =>
        userLevel >=
            (targetUser == user
                ? (content.events[EventType.redaction.type] ??
                      content.eventsDefault)
                : content.redact),
    };
  }

  static final provider = NotifierProvider.autoDispose
      .family<PowerLevelController, bool, PowerLevelConfig>(
        PowerLevelController.new,
      );
}
