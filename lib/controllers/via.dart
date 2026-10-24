import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/power_levels.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

class ViaController(final Room room) extends Notifier<String> {
  @override
  String build() {
    final powerLevelUsers =
        switch (room.state[EventType.powerLevels.type]?[""]) {
          final rowId? => switch (room.events[rowId]?.content) {
            PowerLevelsContent(:final users) => users.keys.toIList(),
            _ => null,
          },
          null => null,
        } ??
        .new([]);

    final joinedMembers =
        (room.state[EventType.membership.type]?.values ?? const [])
            .map(
              (rowId) => switch (room.events[rowId]) {
                Event(
                  stateKey: final userId?,
                  content: MembershipContent(status: .join),
                ) =>
                  userId,
                _ => null,
              },
            )
            .nonNulls
            .toIList();

    final servers = [?ref.watch(ClientStateController.provider)?.userId]
        .toIList()
        .addAll(powerLevelUsers)
        .addAll(joinedMembers)
        .map((userId) => userId.substring(userId.indexOf(":") + 1))
        .whereNoDuplicates()
        .take(5)
        .toISet();

    return servers.isEmpty
        ? ""
        : "?${servers.map((server) => "via=$server").join("&")}";
  }

  static final provider = NotifierProvider.family<ViaController, String, Room>(
    ViaController.new,
  );
}
