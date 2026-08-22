import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:url_launcher/url_launcher.dart" as ul;

class LaunchHelper(Ref ref) {
  Future<bool> launchUrl(Uri url, {bool useWebview = false}) async {
    try {
      return await ul.launchUrl(
        url,
        mode: useWebview ? .inAppBrowserView : .externalApplication,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  static final provider = Provider<LaunchHelper>(LaunchHelper.new);
}
