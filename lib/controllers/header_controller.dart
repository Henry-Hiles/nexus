import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";

class HeaderController extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final client = ref.watch(ClientController.provider.notifier);
    return {"authorization": "Bearer ${await client.getAccessToken()}"};
  }

  static final provider =
      AsyncNotifierProvider<HeaderController, Map<String, String>>(
        HeaderController.new,
      );
}
