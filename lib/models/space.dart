import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/widgets.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/subspace.dart";

part "space.freezed.dart";

@freezed
class const Space({
  required final String id,
  required final String title,
  final IconData? icon,
  final Room? room,
  required final IList<Room> children,
  required final IList<Subspace> subSpaces,
}) with _$Space;
