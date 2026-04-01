import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/profile.dart";

class ProfileController extends AsyncNotifier<Profile> {
  final String userId;
  ProfileController(this.userId);

  @override
  Future<Profile> build() {
    final client = ref.watch(ClientController.provider.notifier);
    return client.getProfile(userId);
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<ProfileController, Profile, String>(ProfileController.new);
}
