import "dart:async";
import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/models/configs/member_config.dart";
import "package:nexus/models/membership.dart";

class MemberController extends AsyncNotifier<Membership> {
  final MemberConfig config;
  MemberController(this.config);

  @override
  FutureOr<Membership> build() {
    final member = ref.watch(
      MembersController.provider(config.room).select(
        (value) => value.firstWhereOrNull(
          (membership) => membership.userId == config.userId,
        ),
      ),
    );
    if (config.room.hasFetchedMembers || member != null) {
      return member ??
          Membership(
            avatarUrl: null,
            displayName: config.userId,
            userId: config.userId,
          );
    }
    return Membership(
      avatarUrl: null,
      displayName: config.userId,
      userId: config.userId,
    );

    throw UnimplementedError();
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<MemberController, Membership, MemberConfig>(
        MemberController.new,
      );
}
