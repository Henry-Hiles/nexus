import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "setting.freezed.dart";

@freezed
abstract class Setting with _$Setting {
  const factory Setting({
    required String title,
    required String description,
    required Widget widget,
  }) = _Setting;
}
