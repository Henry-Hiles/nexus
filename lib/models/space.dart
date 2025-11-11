import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:matrix/matrix.dart";
part "space.freezed.dart";

@freezed
abstract class Space with _$Space {
  const factory Space({required Room roomData, required Image? avatar}) =
      _Space;
}
