import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";

part "subspace.freezed.dart";

@freezed
class const Subspace({
  required final Room room,
  required final IList<Room> children,
}) with _$Subspace;
