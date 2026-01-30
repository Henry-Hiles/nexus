import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/profile.dart";

class ProfileController extends AsyncNotifier<Profile> {
  final String userId;
  ProfileController(this.userId);

  @override
  Future<Profile> build() =>
      ref.watch(ClientController.provider.notifier).getProfile(userId);

  static final provider =
      AsyncNotifierProvider.family<ProfileController, Profile, String>(
        ProfileController.new,
      );
}
