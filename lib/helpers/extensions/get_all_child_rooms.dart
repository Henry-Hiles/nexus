import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/models/room.dart";
import "package:nexus/models/space.dart";

extension GetAllChildRooms on Space {
  IList<Room> get allChildRooms =>
      children.addAll(subSpaces.expand((s) => s.children));
}
