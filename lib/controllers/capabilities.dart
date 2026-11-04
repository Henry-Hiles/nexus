import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/capabilities.dart";

class CapabilitiesController extends AsyncNotifier<Capabilities> {
  @override
  Future<Capabilities> build() =>
      ref.read(ClientController.provider.notifier).getCapabilities();

  static final provider =
      AsyncNotifierProvider<CapabilitiesController, Capabilities>(
        CapabilitiesController.new,
      );
}
