import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/models/configs/members_by_status_config.dart";
import "package:nexus/models/content/membership.dart";
import "package:nexus/models/event.dart";

class MembersByStatusController extends AsyncNotifier<ISet<Event>> {
  final MembersByStatusConfig config;
  MembersByStatusController(this.config);

  @override
  Future<ISet<Event>> build() => ref.watch(
    MembersController.provider(config.roomId).selectAsync(
      (members) => members
          .where(
            (membership) => switch (membership.content) {
              MembershipContent(:final status) => config.status == status,
              _ => false,
            },
          )
          .toISet(),
    ),
  );

  static final provider =
      AsyncNotifierProvider.family<
        MembersByStatusController,
        ISet<Event>,
        MembersByStatusConfig
      >(MembersByStatusController.new);
}
