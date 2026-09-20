import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key.dart";

class PushKeyController(final String instance) extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => json.decode(
    await ref.watch(KeyController.provider(KeyController.pushKeyKey).future) ??
        "{}",
  )[instance];

  Future<void> set(String? value) async {
    final provider = KeyController.provider(KeyController.pushKeyKey);
    final notifier = ref.watch(provider.notifier);
    final prefs = IMap(json.decode(await ref.watch(provider.future) ?? "{}"));

    state = .data(value);
    notifier.set(
      json.encode(
        prefs.add(instance, value).where((_, value) => value != null).unlock,
      ),
    );
  }

  static final provider =
      AsyncNotifierProvider.family<PushKeyController, String?, String>(
        PushKeyController.new,
      );
}
