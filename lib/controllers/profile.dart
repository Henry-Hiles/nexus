import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/profile_response.dart";

class ProfileController(final String userId)
    extends AsyncNotifier<ProfileResponse> {
  @override
  Future<ProfileResponse> build() {
    final client = ref.read(ClientController.provider.notifier);
    return client.getProfile(userId);
  }

  Future<void> setField(String field, Object? value) async {
    await ref
        .read(ClientController.provider.notifier)
        .setProfileField(field, value);
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<ProfileController, ProfileResponse, String>(
        ProfileController.new,
      );
}
