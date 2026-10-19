import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class AppPausedController extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onPause: () => state = true,
      onResume: () => state = false,
    );
    ref.onDispose(listener.dispose);
    return WidgetsBinding.instance.lifecycleState == .paused;
  }

  static final provider = NotifierProvider<AppPausedController, bool>(
    AppPausedController.new,
  );
}
