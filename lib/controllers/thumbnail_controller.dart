import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/models/image_data.dart";

class ThumbnailController extends AsyncNotifier<String?> {
  ThumbnailController(this.data);
  final ImageData data;

  @override
  Future<String?> build({String? from}) async {
    final client = await ref.watch(ClientController.provider.future);
    final uri = await Uri.tryParse(data.uri)?.getDownloadUri(client);

    return uri.toString();
  }

  static final provider = AsyncNotifierProvider.family
      .autoDispose<ThumbnailController, String?, ImageData>(
        ThumbnailController.new,
      );
}
