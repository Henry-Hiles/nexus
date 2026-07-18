import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/setting.dart";
part "settings_category.freezed.dart";

@freezed
abstract class SettingsCategory with _$SettingsCategory {
  const factory SettingsCategory({
    required String title,
    required IconData icon,
    required IList<Setting> settings,
  }) = _SettingsCategory;
}
