import "dart:async";
import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/models/configs/author_config.dart";
import "package:nexus/models/membership.dart";

class AuthorController extends AsyncNotifier<Membership> {
  final AuthorConfig config;
  AuthorController(this.config);

  @override
  Future<Membership> build() async {
    final member = await ref.watch(
      MembersController.provider(config.room).selectAsync(
        (value) => value.firstWhereOrNull(
          (membership) => membership.userId == config.message.authorId,
        ),
      ),
    );

    final pmp = config.message.metadata?["pmp"] == null
        ? null
        : Membership.fromContent(
            IMap(config.message.metadata?["pmp"]),
            config.message.authorId,
            ref.watch(
                  ClientStateController.provider.select(
                    (value) => value?.homeserverUrl,
                  ),
                ) ??
                "",
          );

    return Membership(
      avatarUrl: pmp?.avatarUrl ?? member?.avatarUrl,
      displayName:
          pmp?.displayName ??
          member?.displayName ??
          config.message.authorId.substring(1).split(":").first,
      userId: config.message.authorId,
    );
  }

  static final provider = AsyncNotifierProvider.family<AuthorController, Membership, AuthorConfig>(
        AuthorController.new,
      );
}
