import "package:flutter_riverpod/flutter_riverpod.dart";

class InitCompleteController extends Notifier<bool> {
  @override
  bool build() => false;
  void complete() => state = true;

  static final provider = NotifierProvider<InitCompleteController, bool>(
    InitCompleteController.new,
  );
}
