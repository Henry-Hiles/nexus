import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "space.freezed.dart";

@freezed
abstract class Space with _$Space {
  const factory Space({
    required String id,
    required String title,
    IconData? icon,
    Room? room,
    required IList<Room> children,
  }) = _Space;
}
