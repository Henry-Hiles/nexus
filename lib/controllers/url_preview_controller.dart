import "dart:convert";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/header_controller.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";

class UrlPreviewController extends AsyncNotifier<LinkPreviewData?> {
  final String link;
  UrlPreviewController(this.link);

  @override
  Future<LinkPreviewData?> build() async {
    final homeserver = ref.watch(ClientStateController.provider)?.homeserverUrl;

    if (homeserver != null && !link.contains("matrix.to")) {
      {
        final response = await get(
          Uri.parse(homeserver)
              .resolve("/_matrix/client/v1/media/preview_url")
              .replace(queryParameters: {"url": link}),
          headers: await ref.watch(HeaderController.provider.future),
        );

        if (response.statusCode == 200) {
          final decodedValue = json.decode(response.body);
          final mxc = decodedValue["og:image"];
          final image = mxc == null
              ? null
              : Uri.tryParse(mxc)?.mxcToHttps(homeserver);

          return LinkPreviewData(
            link: link,
            title: decodedValue["og:title"],
            description: decodedValue["og:description"],
            image: image == null
                ? null
                : ImagePreviewData(
                    url: image.toString(),
                    width:
                        (decodedValue["og:image:width"] as int?)?.toDouble() ??
                        0,
                    height:
                        (decodedValue["og:image:height"] as int?)?.toDouble() ??
                        0,
                  ),
          );
        }
      }
    }

    return null;
  }

  static final provider = AsyncNotifierProvider.autoDispose
      .family<UrlPreviewController, LinkPreviewData?, String>(
        UrlPreviewController.new,
      );
}
