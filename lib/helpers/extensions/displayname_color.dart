import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/controllers/settings.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";

extension DisplaynameColor on WidgetRef {
  /// The color of [userId]'s name in [roomId], from their power level
  /// (so everyone with the same level shares one) or their user ID, depending
  /// on the user's settings.
  Color displaynameColor(String roomId, String userId) => switch (watch(
    SettingsController.provider.select((settings) => settings.value?.nameColor),
  )) {
    .user => userId.colorHash,
    .powerLevel || null => powerLevelColor(
      watch(
        RoomPowerLevelsController.provider(roomId)
            .select((levels) => levels.levelOf(userId)),
      ),
    ),
  };

  static Color powerLevelColor(double level) => HSLColor.fromAHSL(
    1,
    level.isInfinite ? 30 : (210 + level / 50 * 137.50776) % 360,
    0.7,
    0.5,
  ).toColor();
}
