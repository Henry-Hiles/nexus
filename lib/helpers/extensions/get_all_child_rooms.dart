import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space.dart";

extension GetAllChildRooms on Space {
  IList<Room> get allChildRooms => subSpaces
      .map((subspace) => subspace.children)
      .toIList()
      .insert(childrenIndex, children)
      .expand((rooms) => rooms)
      .toIList();
}
