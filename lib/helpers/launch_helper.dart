import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:url_launcher/url_launcher.dart" as ul;

class LaunchHelper {
  final Ref ref;
  LaunchHelper(this.ref);

  Future<bool> launchUrl(Uri url, {bool useWebview = false}) async {
    try {
      return await ul.launchUrl(
        url,
        mode: useWebview
            ? ul.LaunchMode.inAppBrowserView
            : ul.LaunchMode.externalApplication,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  static final provider = Provider<LaunchHelper>(LaunchHelper.new);
}
