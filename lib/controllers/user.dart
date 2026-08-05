import "dart:async";
import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members.dart";
import "package:nexus/controllers/profile.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/models/configs/user.dart";
import "package:nexus/models/content/membership.dart";

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

    final profileResponse = await ref.watch(
      ProfileController.provider(config.userId).future,
    );

    return .new(
      status: .leave,
      avatarUrl: profileResponse.profile.avatarUrl,
      displayName:
          profileResponse.profile.displayName ?? config.userId.localpart,
    );
  }

  static final provider =
      AsyncNotifierProvider.family<
        UserController,
        MembershipContent,
        UserConfig
      >(UserController.new);
}
