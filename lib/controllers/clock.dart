import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

class ClockController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final timer = Timer.periodic(
      const .new(seconds: 30),
      (_) => state = .now(),
    );
    ref.onDispose(timer.cancel);
    return .now();
  }

  static final provider =
      NotifierProvider.autoDispose<ClockController, DateTime>(
        ClockController.new,
      );
}
