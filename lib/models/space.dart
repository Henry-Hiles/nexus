import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:matrix/matrix.dart";
import "package:nexus/models/full_room.dart";
part "space.freezed.dart";

@freezed
abstract class Space with _$Space {
  const Space._();
  const factory Space({
    required String title,
    required String id,
    required IList<FullRoom> children,
    required Client client,
    Room? roomData,
    Uri? avatar,
    Icon? icon,
  }) = _Space;
}
