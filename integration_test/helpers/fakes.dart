import "dart:async";

import "package:app_links_platform_interface/app_links_platform_interface.dart";
import "package:url_launcher_platform_interface/link.dart";
import "package:url_launcher_platform_interface/url_launcher_platform_interface.dart";

/// Delivers links to the app as if the OS had opened them.
class FakeAppLinks extends AppLinksPlatform {
  final _links = StreamController<Uri>.broadcast();

  void open(Uri uri) => _links.add(uri);

  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Future<String?> getInitialLinkString() async => null;

  @override
  Future<Uri?> getLatestLink() async => null;

  @override
  Future<String?> getLatestLinkString() async => null;

  @override
  Stream<Uri> get uriLinkStream => _links.stream;

  @override
  Stream<String> get stringLinkStream =>
      _links.stream.map((uri) => uri.toString());
}

/// Hands launched URLs to [onLaunch] instead of opening a browser.
class FakeUrlLauncher(final void Function(Uri url) onLaunch)
    extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    onLaunch(.parse(url));
    return true;
  }
}
