import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/helpers/extensions/string_to_color.dart";

extension DisplaynameColor on WidgetRef {
  /// The color of [userId]'s name in [roomId], hashed from their power level,
  /// so everyone with the same level shares one.
  Color displaynameColor(String roomId, String userId) => watch(
    RoomPowerLevelsController.provider(roomId)
        .select((levels) => levels.levelOf(userId)),
  ).toString().colorHash;
}
