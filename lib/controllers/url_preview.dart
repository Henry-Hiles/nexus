import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/models/open_graph_data.dart";

class UrlPreviewController extends AsyncNotifier<OpenGraphData?> {
  final Uri url;
  UrlPreviewController(this.url);

  @override
  Future<OpenGraphData?> build() async {
    if (url.host == "matrix.to") return null;

    return await ref
        .watch(ClientController.provider.notifier)
        .getUrlPreview(url);
  }

  static final provider =
      AsyncNotifierProvider.family<UrlPreviewController, OpenGraphData?, Uri>(
        UrlPreviewController.new,
      );
}
