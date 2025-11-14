import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extension_helper.dart";
import "package:nexus/models/space.dart";

class SpacesController extends AsyncNotifier<List<Space>> {
  @override
  Future<List<Space>> build() async {
    final client = await ref.watch(ClientController.provider.future);

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

    return [
      Space(
        client: client,
        title: "Home",
        children: topLevelRooms,
        icon: Icon(Icons.home),
        fake: true,
      ),
      Space(
        client: client,
        title: "Direct Messages",
        children: await Future.wait(
          client.rooms
              .where((room) => room.isDirectChat)
              .map((room) => room.fullRoom),
        ),
        icon: Icon(Icons.person),
        fake: true,
      ),
      ...(await Future.wait(
        topLevelSpaces.map(
          (space) async => Space(
            client: client,
            title: space.title,
            avatar: space.avatar,
            children: await Future.wait(
              space.roomData.spaceChildren
                  .map(
                    (child) => client.rooms.firstWhereOrNull(
                      (room) => room.id == child.roomId,
                    ),
                  )
                  .nonNulls
                  .map((room) => room.fullRoom),
            ),
          ),
        ),
      )),
    ];
  }

  static final provider = AsyncNotifierProvider<SpacesController, List<Space>>(
    SpacesController.new,
  );
}
