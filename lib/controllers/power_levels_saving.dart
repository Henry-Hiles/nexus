import "package:flutter_riverpod/flutter_riverpod.dart";

class PowerLevelsSavingController(final String roomId) extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> run(Future<void> Function() action) async {
    state = true;
    try {
      await action();
    } finally {
      if (ref.mounted) state = false;
    }
  }

  static final provider = NotifierProvider.autoDispose
      .family<PowerLevelsSavingController, bool, String>(
        PowerLevelsSavingController.new,
      );
}
