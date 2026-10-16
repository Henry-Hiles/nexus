import "package:material_ui/material_ui.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room_order.dart";

part "settings.freezed.dart";
part "settings.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Settings({
  final ThemeMode theme = ThemeMode.system,
  final bool useDynamicTheming = true,
  final bool linuxMobileMode = false,
  final bool showAllInHome = false,
  final bool showMinimizeButton = false,
  final bool swipeToReply = false,
  final RoomOrder roomOrder = .unreadFirst,
}) with _$Settings {
  Map<String, Object?> toJson() => _$SettingsToJson(this);

  factory Settings.fromJson(Map<String, Object?> json) =>
      _$SettingsFromJson(json);
}
