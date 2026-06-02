import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/user_controller.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";

class AuthorController extends AsyncNotifier<MembershipContent> {
  final Event event;
  AuthorController(this.event);

  @override
  Future<MembershipContent> build() async {
    final member = await ref.watch(
      UserController.provider(
        .new(roomId: event.roomId, userId: event.sender),
      ).future,
    );

    return .new(
      status: member.status,
      avatarUrl: event.pmp?.avatarUrl ?? member.avatarUrl,
      displayName: event.pmp?.displayName ?? member.displayName,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<AuthorController, MembershipContent, Event>(
        AuthorController.new,
      );
}
