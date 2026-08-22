import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/setting.dart";

part "settings_category.freezed.dart";

@freezed
class const SettingsCategory({
  required final String title,
  required final IconData icon,
  required final IList<Setting> settings,
}) with _$SettingsCategory;
