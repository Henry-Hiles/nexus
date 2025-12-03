import "package:collection/collection.dart";
import "package:matrix/matrix.dart";
import "package:nexus/helpers/extensions/get_full_room.dart";
import "package:nexus/models/full_room.dart";

extension RoomToChildren on Room {
  Future<List<FullRoom>> getAllChildren(Client client) async {
    final direct = await Future.wait(
      spaceChildren
          .map(
            (child) => client.rooms
                .firstWhereOrNull((r) => r.id == child.roomId)
                ?.fullRoom,
          )
          .nonNulls,
    );

    return (await Future.wait(
      direct.map(
        (child) async => child.roomData.isSpace
            ? await child.roomData.getAllChildren(client)
            : [child],
      ),
    )).expand((list) => list).toList();
  }
}
