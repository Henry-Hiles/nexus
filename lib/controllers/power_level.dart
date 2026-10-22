import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/models/configs/power_level.dart";
import "package:nexus/models/content/content.dart";

class PowerLevelController(final PowerLevelConfig config)
    extends Notifier<bool> {
  @override
  bool build() {
    if (config case EventPowerLevelConfig(:final eventType)) {
      assert(
        eventType != .redaction,
        "Checking power level for a redaction should use [PowerLevelConfig.redaction].",
      );
    }

    final powerLevels = ref.watch(
      RoomPowerLevelsController.provider(config.roomId),
    );
    final content = powerLevels.content;

    final user = ref.watch(
      ClientStateController.provider.select((value) => value?.userId),
    );
    if (user == null) return false;

    final userLevel = powerLevels.levelOf(user);

    return switch (config) {
      EventPowerLevelConfig(:final eventType) =>
        userLevel >= (content.events[eventType.type] ?? content.eventsDefault),

      MembershipActionPowerLevelConfig(:final action, :final targetUser) =>
        switch (action) {
          .invite => userLevel >= content.invite,

          .kick =>
            userLevel >= content.kick &&
                userLevel > powerLevels.levelOf(targetUser),

          .ban =>
            userLevel >= content.ban &&
                userLevel > powerLevels.levelOf(targetUser),

          .unban => userLevel >= content.ban,
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
