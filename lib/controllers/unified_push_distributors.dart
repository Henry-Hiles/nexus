import "dart:io";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:unifiedpush/unifiedpush.dart";

class UnifiedPushDistributorsController extends AsyncNotifier<IList<String>> {
  @override
  Future<IList<String>> build() async {
    if (!Platform.isLinux && !Platform.isAndroid) return .new();

    return IList(
      await UnifiedPush.getDistributors().timeout(
        .new(seconds: 10),
        onTimeout: () =>
            throw Exception("UnifiedPush distributor check timed out."),
      ),
    );
  }

  static final provider =
      AsyncNotifierProvider.autoDispose<
        UnifiedPushDistributorsController,
        IList<String>
      >(UnifiedPushDistributorsController.new);
}
