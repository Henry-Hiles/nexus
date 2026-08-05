import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/profile_response.dart";

class ProfileController extends AsyncNotifier<ProfileResponse> {
  final String userId;
  ProfileController(this.userId);

  @override
  Future<ProfileResponse> build() {
    final client = ref.watch(ClientController.provider.notifier);
    return client.getProfile(userId);
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<ProfileController, ProfileResponse, String>(
        ProfileController.new,
      );
}
