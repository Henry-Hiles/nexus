import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/spec_versions_response.dart";

class SpecVersionsController extends AsyncNotifier<SpecVersionsResponse> {
  @override
  Future<SpecVersionsResponse> build() =>
      ref.watch(ClientController.provider.notifier).getSpecVersions();

  static final provider =
      AsyncNotifierProvider.autoDispose<
        SpecVersionsController,
        SpecVersionsResponse
      >(SpecVersionsController.new);
}
