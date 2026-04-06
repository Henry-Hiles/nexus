import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/models/room.dart";

class ViaController extends Notifier<String> {
  final Room room;
  ViaController(this.room);

  @override
  String build() {
    final servers = <String>{};

    void addUserId(String? userId) {
      final server = userId?.split(":").lastOrNull;
      if (server != null) {
        servers.add(server);
      }
    }

    addUserId(ref.watch(ClientStateController.provider)?.userId);

    final powerLevels = room.events.firstWhereOrNull(
      (event) => event.rowId == room.state["m.room.power_levels"]?[""],
    );

    for (final userId in IMap(powerLevels?.content["users"]).keys) {
      addUserId(userId);
      if (servers.length >= 5) break;
    }

    final members = room.state["m.room.member"]?.values.toIList();
    for (var i = 0; servers.length < 5; i++) {
      final member = room.events.firstWhereOrNull(
        (event) => event.rowId == members?.getOrNull(i),
      );

      if (member?.content["membership"] == "join") {
        addUserId(member?.stateKey);
      }

      if (members?.getOrNull(i) == null) break;
    }

    return servers.isEmpty
        ? ""
        : "?${servers.map((server) => "via=$server").join("&")}";
  }

  static final provider = NotifierProvider.family<ViaController, String, Room>(
    ViaController.new,
  );
}
