import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:unifiedpush/unifiedpush.dart";

class UnifiedPushAllowedController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    if (!await UnifiedPush.tryUseCurrentOrDefaultDistributor()) {
      return "No valid distributors found. Try installing ${Platform.isLinux
          ? "KUnifiedPush"
          : Platform.isAndroid
          ? "Google Play Services or NTFY"
          : "NTFY"}.";
    }

    final capabilities = await ref
        .watch(ClientController.provider.notifier)
        .getCapabilities();

    if (capabilities.webpush?.vapid == null) {
      return "Your homeserver does not support MSC4174 (Web Push), and therefore cannot send notifications to Nexus.";
    }

    return null;
  }

  static final provider =
      AsyncNotifierProvider.autoDispose<UnifiedPushAllowedController, String?>(
        UnifiedPushAllowedController.new,
      );
}
