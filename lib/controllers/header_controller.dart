import "package:ffi/ffi.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/src/third_party/gomuks.g.dart";

class HeaderController extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final handle = await ref.watch(ClientController.provider.future);
    final info = GomuksGetAccountInfo(handle);
    final headers = {
      "authorization":
          "Bearer ${info.access_token.cast<Utf8>().toDartString()}",
    };

    GomuksFreeAccountInfo(info);
    return headers;
  }

  static final provider =
      AsyncNotifierProvider<HeaderController, Map<String, String>>(
        HeaderController.new,
      );
}
