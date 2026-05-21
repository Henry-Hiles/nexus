import "dart:async";
import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/controllers/profile_controller.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/configs/user_config.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/membership_status.dart";

class UserController extends AsyncNotifier<MembershipContent> {
  final UserConfig config;
  UserController(this.config);

  @override
  Future<MembershipContent> build() async {
    final member = config.roomId == null
        ? null
        : await ref.watch(
            MembersController.provider(config.roomId!).selectAsync(
              (value) => value.firstWhereOrNull(
                (membership) => membership.stateKey == config.userId,
              ),
            ),
          );

    if (member?.content case final MembershipContent content) {
      return content;
    }

    final profile = await ref.watch(
      ProfileController.provider(config.userId).future,
    );
    return MembershipContent(
      status: MembershipStatus.leave,
      avatarUrl: profile.avatarUrl,
      displayName: profile.displayName ?? config.userId.localpart,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<
        UserController,
        MembershipContent,
        UserConfig
      >(UserController.new);
}
