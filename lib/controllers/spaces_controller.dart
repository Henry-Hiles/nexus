import "package:flutter/widgets.dart";
import "package:matrix/matrix.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/space.dart";

class SpacesController extends AsyncNotifier<List<Space>> {
  @override
  Future<List<Space>> build() async {
    final client = await ref.watch(ClientController.provider.future);

    return Future.wait(
      client.rooms.where((room) => room.isSpace).map((data) async {
        final thumb = await data.avatar?.getThumbnailUri(
          client,
          width: 40,
          height: 40,
        );
        return Space(
          roomData: data,
          avatar: thumb == null
              ? null
              : Image.network(
                  thumb.toString(),
                  width: 40,
                  headers: {"authorization": "Bearer ${client.accessToken}"},
                ),
        );
      }),
    );
  }

  static final provider = AsyncNotifierProvider<SpacesController, List<Space>>(
    SpacesController.new,
  );
}
