import "dart:convert";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/header_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/models/open_graph_data.dart";

class UrlPreviewController extends AsyncNotifier<OpenGraphData?> {
  final String link;
  UrlPreviewController(this.link);

  @override
  Future<OpenGraphData?> build() async {
    try {
      final homeserver = ref.watch(
        ClientStateController.provider.select((value) => value?.homeserverUrl),
      );

      if (homeserver != null && !link.contains("matrix.to")) {
        {
          final response = await get(
            .parse(homeserver)
                .resolve("/_matrix/client/v1/media/preview_url")
                .replace(queryParameters: {"url": link}),
            headers: await ref.watch(HeaderController.provider.future),
          );

          if (response.statusCode == 200) {
            final decodedValue = json.decode(response.body);
            if (decodedValue is! Map<String, dynamic>) return null;

            final mxc = decodedValue["og:image"];
            final image = mxc == null
                ? null
                : Uri.tryParse(mxc)?.mxcToHttps(homeserver);

            return .fromJson(decodedValue).copyWith(imageUrl: image);
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static final provider =
      AsyncNotifierProvider.family<
        UrlPreviewController,
        OpenGraphData?,
        String
      >(UrlPreviewController.new);
}
