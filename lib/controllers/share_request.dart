import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:receive_sharing_intent/receive_sharing_intent.dart";

class ShareRequestController extends Notifier<IList<SharedMediaFile>?> {
  @override
  IList<SharedMediaFile>? build() {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;

    void receive(List<SharedMediaFile> files) {
      final shared = files
          // Android reports opened Matrix links as URLs too, which
          // LinkRequestController handles
          .where((file) => !(Platform.isAndroid && file.type == .url))
          .toIList();
      if (shared.isNotEmpty) state = shared;
    }

    final sharing = ReceiveSharingIntent.instance;
    final subscription = sharing.getMediaStream().listen(receive);
    ref.onDispose(subscription.cancel);
    sharing.getInitialMedia().then(receive).ignore();

    return null;
  }

  void consume() {
    state = null;
    // So the same share isn't received again once the app is reopened
    ReceiveSharingIntent.instance.reset().ignore();
  }

  static final provider =
      NotifierProvider<ShareRequestController, IList<SharedMediaFile>?>(
        ShareRequestController.new,
      );
}
