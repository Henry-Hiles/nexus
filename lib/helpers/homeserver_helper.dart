import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";

class HomeserverHelper {
  final Ref ref;
  HomeserverHelper(this.ref);

  Future<bool> setHomeserver(Uri homeserverUrl) async {
    final client = await ref.watch(ClientController.provider.future);
    try {
      await client.checkHomeserver(homeserverUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  static final provider = Provider<HomeserverHelper>(HomeserverHelper.new);
}
