import "package:app_links/app_links.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";

class LinkRequestController extends Notifier<LinkInfo?> {
  @override
  LinkInfo? build() {
    final subscription = AppLinks().uriLinkStream.listen((uri) {
      if (uri.toString().linkInfo case final linkInfo?) state = linkInfo;
    });
    ref.onDispose(subscription.cancel);

    return null;
  }

  void consume() => state = null;

  static final provider = NotifierProvider<LinkRequestController, LinkInfo?>(
    LinkRequestController.new,
  );
}
