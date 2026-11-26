import "dart:io";

import "package:better_share_handler/better_share_handler.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class ShareRequestController extends Notifier<SharedMedia?> {
  @override
  SharedMedia? build() {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;

    final sharing = ShareHandler.instance;
    final subscription = sharing.sharedMediaStream.listen(
      (media) => state = media,
    );
    ref.onDispose(subscription.cancel);
    sharing.getInitialSharedMedia().then((media) {
      if (media != null) state = media;
    }).ignore();

    return null;
  }

  void consume() {
    state = null;
    // So the same share isn't received again once the app is reopened
    ShareHandler.instance.resetInitialSharedMedia().ignore();
  }

  static final provider =
      NotifierProvider<ShareRequestController, SharedMedia?>(
        ShareRequestController.new,
      );
}
