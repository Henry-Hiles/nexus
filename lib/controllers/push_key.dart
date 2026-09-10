import "dart:convert";

import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/key.dart";

class PushKeyController(final String instance) extends Notifier<String?> {
  @override
  String? build() => json.decode(
    ref.watch(KeyController.provider(KeyController.pushKeyKey)) ?? "{}",
  )[instance];

  Future<void> set(String? value) async {
    final provider = KeyController.provider(KeyController.pushKeyKey);
    final notifier = ref.watch(provider.notifier);
    final prefs = IMap(json.decode(ref.watch(provider) ?? "{}"));

    state = value;
    notifier.set(
      json.encode(
        prefs.add(instance, value).where((_, value) => value != null).unlock,
      ),
    );
  }

  static final provider =
      NotifierProvider.family<PushKeyController, String?, String>(
        PushKeyController.new,
      );
}
