import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/profile_response.dart";

class ProfileController(final String userId)
    extends AsyncNotifier<ProfileResponse> {
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
