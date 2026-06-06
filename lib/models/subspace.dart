import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "subspace.freezed.dart";

@freezed
abstract class Subspace with _$Subspace {
  const factory Subspace({required Room room, required IList<Room> children}) =
      _Subspace;
}
