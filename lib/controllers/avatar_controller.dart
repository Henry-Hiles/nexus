import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/client_controller.dart";

class AvatarController extends AsyncNotifier<Uri> {
  final String mxc;
  AvatarController(this.mxc);
  @override
  Future<Uri> build() async => Uri.parse(mxc).getThumbnailUri(
    await ref.watch(ClientController.provider.future),
    width: 24,
    height: 24,
  );

  static final provider = AsyncNotifierProvider.family
      .autoDispose<AvatarController, Uri, String>(AvatarController.new);
}
