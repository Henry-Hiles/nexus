import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/full_room.dart";
part "space.freezed.dart";

@freezed
abstract class Space with _$Space {
  const factory Space({
    required String title,
    required Widget? avatar,
    required List<FullRoom> children,
    @Default(false) bool fake,
  }) = _Space;
}
