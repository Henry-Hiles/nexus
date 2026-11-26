import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/profile.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/profile_response.dart";
import "package:nexus/models/room.dart";

/// The current user's member event content in [roomId], which holds the
/// avatar and display name they have there, fetching only that event if it
/// hasn't been yet.
class RoomProfileController(final String roomId)
    extends AsyncNotifier<MembershipContent?> {
  String? get _userId => ref.read(ClientStateController.provider)?.userId;

  @override
  Future<MembershipContent?> build() async {
    final userId = ref.watch(
      ClientStateController.provider.select((state) => state?.userId),
    );
    if (userId == null) return null;

    MembershipContent? memberOf(IMap<String, Room> rooms) =>
        switch (rooms[roomId]) {
          final room? =>
            switch (room.state[EventType.membership.type]?[userId]) {
              final rowId? => switch (room.events[rowId]?.content) {
                final MembershipContent content => content,
                _ => null,
              },
              null => null,
            },
          null => null,
        };

    if (memberOf(ref.read(RoomsController.provider)) == null) {
      ref
          .read(RoomsController.provider.notifier)
          .addSpecificState(
            await ref
                .read(ClientController.provider.notifier)
                .getSpecificRoomState(
                  .new(
                    keys: .new([
                      .new(
                        roomId: roomId,
                        type: EventType.membership.type,
                        stateKey: userId,
                      ),
                    ]),
                  ),
                ),
          );
    }

    return ref.watch(RoomsController.provider.select(memberOf));
  }

  /// Sets [changes] in the member event, waiting for it to come down sync.
  Future<void> setFields(IMap<String, Object?> changes) async {
    final userId = _userId;
    if (userId == null) return;

    final eventId = await ref
        .read(ClientController.provider.notifier)
        .updateMembership(roomId, userId, changes);
    if (eventId != null) {
      await ref
          .read(RoomsController.provider.notifier)
          .awaitState(
            roomId,
            EventType.membership.type,
            eventId,
            stateKey: userId,
          );
    }
  }

  /// Replaces the room's avatar and display name with the global ones.
  Future<void> reset() async {
    final userId = _userId;
    if (userId == null) return;

    final profile = (await ref.read(ProfileController.provider(userId).future))
        .profile;
    await setFields(
      .new({
        Profile.displayNameKey: profile.displayName,
        Profile.avatarUrlKey: profile.avatarUrl?.toString(),
      }),
    );
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<RoomProfileController, MembershipContent?, String>(
        RoomProfileController.new,
      );
}
