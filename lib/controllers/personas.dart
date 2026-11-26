import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/controllers/rooms.dart";
import "package:nexus/models/account_data.dart";
import "package:nexus/models/per_message_profiles.dart";

typedef RoomPersonas = ({
  IList<StoredProfile> profiles,
  StoredProfile? current,
});

class PersonasController(final String roomId) extends Notifier<RoomPersonas> {
  @override
  RoomPersonas build() {
    final global = ref.watch(
      AccountDataController.provider.select((data) => data.perMessageProfiles),
    );
    final roomJson = ref.watch(
      RoomsController.provider.select(
        (rooms) =>
            rooms[roomId]?.accountData[AccountData.perMessageProfilesKey],
      ),
    );

    PerMessageProfiles? room;
    if (roomJson != null) {
      try {
        room = .fromJson(roomJson);
      } catch (error) {
        debugPrint("Ignoring invalid room per-message profiles: $error");
      }
    }

    final roomIds = room?.profiles.map((profile) => profile.id).toISet();
    final profiles = (room?.profiles ?? const IList<StoredProfile>.empty())
        .addAll(
          global.profiles.where(
            (profile) => !(roomIds?.contains(profile.id) ?? false),
          ),
        );

    final currentId = room?.defaultProfileId ?? global.defaultProfileId;
    return (
      profiles: profiles,
      current: currentId == null || currentId.isEmpty
          ? null
          : profiles.firstWhereOrNull((profile) => profile.id == currentId),
    );
  }

  static final provider = NotifierProvider.autoDispose
      .family<PersonasController, RoomPersonas, String>(PersonasController.new);
}
