import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extensions/get_full_room.dart";
import "package:nexus/models/full_room.dart";

class RoomsController extends AsyncNotifier<IList<FullRoom>> {
  @override
  Future<IList<FullRoom>> build() async {
    final client = await ref.watch(ClientController.provider.future);

    ref.onDispose(
      client.onSync.stream.listen((_) => ref.invalidateSelf()).cancel,
    );

    return IList(await Future.wait(client.rooms.map((room) => room.fullRoom)));
  }

  static final provider =
      AsyncNotifierProvider<RoomsController, IList<FullRoom>>(
        RoomsController.new,
      );
}
