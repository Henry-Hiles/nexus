import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";

class HeaderController extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    if (ref.watch(ClientStateController.provider)?.isLoggedIn != true) {
      return {};
    }
    final client = ref.watch(ClientController.provider.notifier);
    final accessToken = await client.getAccessToken();
    return {"authorization": "Bearer $accessToken"};
  }

  static final provider =
      AsyncNotifierProvider<HeaderController, Map<String, String>>(
        HeaderController.new,
      );
}
