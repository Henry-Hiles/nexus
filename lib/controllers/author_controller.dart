import "dart:async";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/membership_status.dart";

class AuthorController extends AsyncNotifier<Membership> {
  final Message message;
  AuthorController(this.message);

  @override
  Future<Membership> build() async {
    final member = await ref.watch(
      MembersController.provider.selectAsync(
        (value) => value.firstWhereOrNull(
          (membership) => membership.userId == message.authorId,
        ),
      ),
    );

    final pmp = message.metadata?["pmp"] == null
        ? null
        : Membership.fromContent(
            IMap(message.metadata?["pmp"]),
            message.authorId,
            ref.watch(
                  ClientStateController.provider.select(
                    (value) => value?.homeserverUrl,
                  ),
                ) ??
                "",
          );

    return Membership(
      status: member?.status ?? MembershipStatus.leave,
      avatarUrl: pmp?.avatarUrl ?? member?.avatarUrl,
      displayName:
          pmp?.displayName ??
          member?.displayName ??
          message.authorId.substring(1).split(":").first,
      userId: message.authorId,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<AuthorController, Membership, Message>(
        AuthorController.new,
      );
}
