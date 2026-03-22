import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/room.dart";

class MembersController extends Notifier<IList<Membership>> {
  final Room room;
  MembersController(this.room);

  @override
  IList<Membership> build() => (room.state["m.room.member"]?.values ?? [])
      .map(
        (eventRowId) =>
            room.events.firstWhereOrNull((event) => event.rowId == eventRowId),
      )
      .nonNulls
      .where((member) => member.content["membership"] == "join")
      .map(
        (membership) => Membership(
          avatarUrl: Uri.tryParse(membership.content["avatar_url"] ?? ""),
          userId: membership.stateKey!,
          displayName: membership.content["displayname"] ?? membership.stateKey,
        ),
      )
      .toIList();

  static final provider = NotifierProvider.family
      .autoDispose<MembersController, IList<Membership>, Room>(
        MembersController.new,
      );
}
