import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "power_levels.freezed.dart";
part "power_levels.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PowerLevelsContent({
  final IMap<String, int> events = const .empty(),
  final IMap<String, int> users = const .empty(),
  @JsonKey(includeIfNull: false) final Notifications? notifications,
  final int ban = 50,
  final int eventsDefault = 0,
  final int invite = 0,
  final int kick = 50,
  final int redact = 50,
  final int stateDefault = 50,
  final int usersDefault = 0,
}) extends Content with _$PowerLevelsContent {
  @override
  Map<String, Object?> toJson() => _$PowerLevelsContentToJson(this);

  factory PowerLevelsContent.fromJson(Map<String, Object?> json) =>
      _$PowerLevelsContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const Notifications({final int room = 50}) with _$Notifications {
  Map<String, Object?> toJson() => _$NotificationsToJson(this);

  factory Notifications.fromJson(Map<String, Object?> json) =>
      _$NotificationsFromJson(json);
}
