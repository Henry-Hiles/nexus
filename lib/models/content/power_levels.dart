import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "power_levels.freezed.dart";
part "power_levels.g.dart";

@freezed
abstract class PowerLevelsContent extends Content with _$PowerLevelsContent {
  PowerLevelsContent._();
  factory PowerLevelsContent({
    @Default(IMap.empty()) IMap<String, int> events,
    @Default(IMap.empty()) IMap<String, int> users,
    Notifications? notifications,
    @Default(50) int ban,
    @Default(0) int eventsDefault,
    @Default(0) int invite,
    @Default(50) int kick,
    @Default(50) int redact,
    @Default(50) int stateDefault,
    @Default(0) int usersDefault,
  }) = _PowerLevelsContent;

  factory PowerLevelsContent.fromJson(Map<String, Object?> json) =>
      _$PowerLevelsContentFromJson(json);
}

@freezed
abstract class Notifications with _$Notifications {
  const factory Notifications({
    @Default(50) int room,
    @Default(IMapConst({})) IMap<String, int> other,
  }) = _Notifications;

  factory Notifications.fromJson(Map<String, Object?> json) =>
      _$NotificationsFromJson(json);
}
