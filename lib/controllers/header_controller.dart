import "dart:ffi";
import "dart:isolate";
import "package:ffi/ffi.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/src/third_party/gomuks.g.dart";

class HeaderController extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final handle = await ref.watch(ClientController.provider.future);
    final info = await Isolate.run(() => GomuksGetAccountInfo(handle));
    final headers = {
      if (info.access_token != nullptr)
        "authorization":
            "Bearer ${info.access_token.cast<Utf8>().toDartString()}",
    };

    await Isolate.run(() => GomuksFreeAccountInfo(info));
    return headers;
  }

  static final provider =
      AsyncNotifierProvider<HeaderController, Map<String, String>>(
        HeaderController.new,
      );
}
