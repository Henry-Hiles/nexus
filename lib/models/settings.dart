import "package:material_ui/material_ui.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room_order.dart";
import "package:nexus/models/show_and_send.dart";

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
  final bool hideMembershipEvents = false,
  final RoomOrder roomOrder = .unreadFirst,
  final ShowAndSend typingIndicators = .showAndSend,

  /// When not sending, read receipts are still sent privately, so that the
  /// user's other devices know what has been read.
  final ShowAndSend readReceipts = .showAndSend,
}) with _$Settings {
  Map<String, Object?> toJson() => _$SettingsToJson(this);

  factory Settings.fromJson(Map<String, Object?> json) =>
      _$SettingsFromJson(json);
}
