import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/user.dart";
import "package:nexus/models/configs/author.dart";
import "package:nexus/models/content/membership.dart";

class AuthorController(final AuthorConfig config)
    extends AsyncNotifier<MembershipContent> {
  @override
  Future<MembershipContent> build() async {
    final member = await ref.watch(
      UserController.provider(
        .new(roomId: config.roomId, userId: config.userId),
      ).future,
    );

    return .new(
      status: member.status,
      avatarUrl: config.avatarUrl ?? member.avatarUrl,
      displayName: config.displayName ?? member.displayName,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<
        AuthorController,
        MembershipContent,
        AuthorConfig
      >(AuthorController.new);
}
