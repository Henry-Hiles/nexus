import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/power_levels.dart";
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

    final powerLevelsEventId = room.state[EventType.powerLevels.type]?[""];
    final powerLevels = powerLevelsEventId == null
        ? null
        : room.events[powerLevelsEventId];

    if (powerLevels?.content case PowerLevelsContent(:final users)) {
      for (final userId in users.keys) {
        addUserId(userId);
        if (servers.length >= 5) break;
      }
    }

    final members = room.state[EventType.membership.type]?.values.toIList();
    for (var i = 0; servers.length < 5; i++) {
      final membershipEventId = members?.getOrNull(i);
      final member = membershipEventId == null
          ? null
          : room.events[membershipEventId];

      if (member?.content case MembershipContent(:final status)) {
        if (status == .join) {
          addUserId(member?.stateKey);
        }
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
