import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extensions/get_full_room.dart";
import "package:nexus/helpers/extensions/room_to_children.dart";
import "package:nexus/models/space.dart";

class SpacesController extends AsyncNotifier<IList<Space>> {
  @override
  Future<IList<Space>> build() async {
    final client = await ref.watch(ClientController.provider.future);

    ref.onDispose(
      client.onSync.stream.listen((_) => ref.invalidateSelf()).cancel,
    );

    final topLevel = await Future.wait(
      client.rooms
          .where((room) => !room.isDirectChat)
          .where(
            (room) => client.rooms
                .where((room) => room.isSpace)
                .every(
                  (match) => match.spaceChildren.every(
                    (child) => child.roomId != room.id,
                  ),
                ),
          )
          .map((room) => room.fullRoom),
    );

    final topLevelSpaces = topLevel.where((r) => r.roomData.isSpace).toList();
    final topLevelRooms = topLevel.where((r) => !r.roomData.isSpace).toList();

    return IList([
      Space(
        client: client,
        title: "Home",
        id: "home",
        children: topLevelRooms,
        icon: Icon(Icons.home),
      ),
      Space(
        client: client,
        title: "Direct Messages",
        id: "dms",
        children: await Future.wait(
          client.rooms
              .where((room) => room.isDirectChat)
              .map((room) => room.fullRoom),
        ),
        icon: Icon(Icons.person),
      ),
      ...(await Future.wait(
        topLevelSpaces.map(
          (space) async => Space(
            client: client,
            title: space.title,
            avatar: space.avatar,
            id: space.roomData.id,
            roomData: space.roomData,
            children: await space.roomData.getAllChildren(client),
          ),
        ),
      )),
    ]);
  }

  static final provider = AsyncNotifierProvider<SpacesController, IList<Space>>(
    SpacesController.new,
  );
}
