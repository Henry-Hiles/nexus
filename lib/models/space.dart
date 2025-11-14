import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:matrix/matrix.dart";
import "package:nexus/models/full_room.dart";
part "space.freezed.dart";

@freezed
abstract class Space with _$Space {
  const factory Space({
    required String title,
    required List<FullRoom> children,
    required Client client,
    @Default(false) bool fake,
    Uri? avatar,
    Icon? icon,
  }) = _Space;
}
