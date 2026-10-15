import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/content/avatar.dart";
import "package:nexus/models/content/canonical_alias.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/content/create.dart";
import "package:nexus/models/content/encryption.dart";
import "package:nexus/models/content/history_visibility.dart";
import "package:nexus/models/content/join_rules.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/content/name.dart";
import "package:nexus/models/content/topic.dart";
import "package:nexus/models/invited_room.dart";
import "package:nexus/models/room_summary.dart";

/// Pending invites, newest first.
class InvitesController extends Notifier<IList<RoomSummary>> {
  @override
  IList<RoomSummary> build() => .new();

  /// Adds new invites, and removes invites for rooms that have since been
  /// joined or left.
  void update(
    IList<InvitedRoom> invitedRooms, {
    ISet<String> joinedRooms = const .empty(),
    ISet<String> leftRooms = const .empty(),
  }) {
    final userId = ref.read(ClientStateController.provider)?.userId;

    RoomSummary toSummary(InvitedRoom invite) {
      final summary = invite.inviteState.fold(
        RoomSummary(roomId: invite.roomId, membership: .invite),
        (summary, event) => switch (event.content) {
          NameContent(:final name) when name.isNotEmpty => summary.copyWith(
            name: name,
          ),
          AvatarContent(:final url) => summary.copyWith(avatarUrl: url),
          TopicContent(:final topic) when topic.isNotEmpty => summary.copyWith(
            topic: topic,
          ),
          CanonicalAliasContent(:final alias) => summary.copyWith(
            canonicalAlias: alias,
          ),
          JoinRulesContent(:final joinRule) => summary.copyWith(
            joinRule: joinRule,
          ),
          CreateContent(:final type, :final roomVersion) => summary.copyWith(
            roomType: type,
            roomVersion: roomVersion,
          ),
          EncryptionContent(:final algorithm) => summary.copyWith(
            encryption: algorithm,
          ),
          HistoryVisibilityContent(:final historyVisibility) =>
            summary.copyWith(
              worldReadable: historyVisibility == .worldReadable,
            ),
          MembershipContent(:final isDirect) when event.stateKey == userId =>
            summary.copyWith(invitedBy: event.sender, isDirect: isDirect),
          _ => summary,
        },
      );

      // The inviter is only known once the user's own invite has been found
      final inviterProfile = switch (invite.inviteState
          .firstWhereOrNull(
            (event) =>
                event.type == EventType.membership.type &&
                event.stateKey == summary.invitedBy,
          )
          ?.content) {
        MembershipContent content => content,
        _ => null,
      };

      return summary.copyWith(
        inviterProfile: inviterProfile,
        // Direct messages usually have no name, so use the inviter's
        name:
            summary.name ??
            (summary.isDirect
                ? inviterProfile?.displayName ?? summary.invitedBy?.localpart
                : null),
      );
    }

    final newInvites = invitedRooms.map(toSummary).toIList();
    final newRoomIds = newInvites.map((invite) => invite.roomId).toISet();
    final removed = joinedRooms.addAll(leftRooms);

    state = newInvites
        .addAll(state.where((invite) => !newRoomIds.contains(invite.roomId)))
        .removeWhere((invite) => removed.contains(invite.roomId));
  }

  void remove(String roomId) =>
      state = state.removeWhere((invite) => invite.roomId == roomId);

  Future<void> decline(String roomId) async {
    await ref.read(ClientController.provider.notifier).leaveRoom(roomId);
    remove(roomId);
  }

  /// Declines every invite, removing each as it succeeds. If any fail, the
  /// first error is thrown once all have finished.
  Future<void> declineAll() =>
      Future.wait(state.map((invite) => decline(invite.roomId)));

  static final provider =
      NotifierProvider<InvitesController, IList<RoomSummary>>(
        InvitesController.new,
      );
}
