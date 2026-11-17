import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_error_snack_bar.dart";
import "package:nexus/main.dart";
import "package:url_launcher/url_launcher.dart" as ul;

class LaunchHelper(Ref ref) {
  Future<bool> launchUrl(Uri url, {bool useWebview = false}) async {
    final launched = await ul
        .launchUrl(
          url,
          mode: useWebview ? .inAppBrowserView : .externalApplication,
        )
        .catchError((_) => false, test: (error) => error is PlatformException);

    if (navigatorKey.currentContext case final context?
        when !launched && context.mounted) {
      ScaffoldMessenger.of(context).showErrorSnackBar(
        "Couldn't open $url. Is there a browser installed?",
        action: (
          label: "Copy link",
          onPressed: () => Clipboard.setData(.new(text: url.toString())),
        ),
      );
    }
    return launched;
  }

  static final provider = Provider<LaunchHelper>(LaunchHelper.new);
}
