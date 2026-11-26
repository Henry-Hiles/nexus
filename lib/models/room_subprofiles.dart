import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/per_message_profiles.dart";

part "room_subprofiles.freezed.dart";

@freezed
class const RoomSubprofiles({
  required final IList<StoredProfile> profiles,
  // Each trigger is tried in this order, as gomuks does when sending
  required final IList<StoredProfile> triggerOrder,
  final StoredProfile? current,
}) with _$RoomSubprofiles {
  StoredProfile? triggeredBy(String text) => triggerOrder.firstWhereOrNull(
    (profile) =>
        profile.id.isNotEmpty &&
        profile.triggers.any((trigger) => trigger.matches(text)),
  );
}
