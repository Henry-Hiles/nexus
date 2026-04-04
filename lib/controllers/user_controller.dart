import "dart:async";
import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/membership_status.dart";

class UserController extends AsyncNotifier<Membership?> {
  final String userId;
  UserController(this.userId);

  @override
  Future<Membership?> build() async {
    final member = await ref.watch(
      MembersController.provider.selectAsync(
        (value) =>
            value.firstWhereOrNull((membership) => membership.userId == userId),
      ),
    );

    if (member != null) return member;

    final profile = await ref.watch(ProfileController.provider(userId).future);
    return Membership(
      status: MembershipStatus.leave,
      avatarUrl: profile.avatarUrl == null
          ? null
          : Uri.tryParse(profile.avatarUrl!),
      displayName: profile.displayName ?? userId.localpart,
      userId: userId,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<UserController, Membership?, String>(
        UserController.new,
      );
}
