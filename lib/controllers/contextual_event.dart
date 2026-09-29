import "package:flutter_riverpod/flutter_riverpod.dart";

class ContextualEventController(String? _) extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? event) => state = event;

  @override
  bool updateShouldNotify(_, _) => true;

  static final provider = NotifierProvider.family
      .autoDispose<ContextualEventController, int?, String?>(
        ContextualEventController.new,
      );
}
