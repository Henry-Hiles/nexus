import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/members_controller.dart";
import "package:nexus/models/membership.dart";
import "package:nexus/models/membership_status.dart";

class MembersByTypeController extends AsyncNotifier<IList<Membership>> {
  final MembershipStatus status;
  MembersByTypeController(this.status);

  @override
  Future<IList<Membership>> build() => ref.watch(
    MembersController.provider.selectAsync(
      (members) =>
          members.where((membership) => membership.status == status).toIList(),
    ),
  );

  static final provider =
      AsyncNotifierProvider.family<
        MembersByTypeController,
        IList<Membership>,
        MembershipStatus
      >(MembersByTypeController.new);
}
