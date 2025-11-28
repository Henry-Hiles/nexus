import "package:matrix/matrix.dart";
import "package:nexus/models/full_room.dart";

extension GetFullRoom on Room {
  Future<FullRoom> get fullRoom async {
    await loadHeroUsers();
    return FullRoom(
      roomData: this,
      title: getLocalizedDisplayname(),
      avatar: await avatar?.getThumbnailUri(client, width: 24, height: 24),
    );
  }
}
