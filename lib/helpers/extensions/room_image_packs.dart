import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/image_pack.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/image_pack.dart";
import "package:nexus/models/room.dart";

extension RoomImagePacks on Room {
  /// The room's image packs by state key, preferring the stable type when a
  /// pack has both, and leaving out deleted ones. [roomId] names those without
  /// a name when the room has none either.
  IMap<String, ImagePack> imagePacks(String roomId) => .fromEntries(
    const [EventType.legacyImagePack, EventType.imagePack].expand(
      (type) => (state[type.type] ?? .new()).entries
          .map(
            (entry) => switch (events[entry.value]) {
              Event(redactedBy: null, content: final ImagePackContent content)
                  when content.hasContent =>
                MapEntry(
                  entry.key,
                  ImagePack.fromContent(
                    content,
                    roomId: roomId,
                    roomName: metadata?.name ?? roomId,
                    stateKey: entry.key,
                  ),
                ),
              _ => null,
            },
          )
          .nonNulls,
    ),
  );
}
