import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "settings.freezed.dart";
part "settings.g.dart";

@freezed
abstract class Settings with _$Settings {
  const factory Settings({
    @Default(ThemeMode.system) ThemeMode theme,
    @Default(true) bool useDynamicTheming,
    @Default(false) bool linuxMobileMode,
  }) = _Settings;

  factory Settings.fromJson(Map<String, Object?> json) =>
      _$SettingsFromJson(json);
}
