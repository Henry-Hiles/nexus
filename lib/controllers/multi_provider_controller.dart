import "dart:async";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class MultiProviderController extends AsyncNotifier<void> {
  MultiProviderController(this.providers);
  final IList<AsyncNotifierProvider> providers;

  @override
  FutureOr<void> build() async => await Future.wait(
    providers.map((provider) => ref.watch(provider.future)),
  );

  static final provider =
      AsyncNotifierProvider.family<
        MultiProviderController,
        void,
        IList<AsyncNotifierProvider>
      >(MultiProviderController.new);
}
