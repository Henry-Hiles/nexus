import "package:flutter_riverpod/flutter_riverpod.dart";

class SelectedSpaceController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;

  static final provider = NotifierProvider<SelectedSpaceController, int>(
    SelectedSpaceController.new,
  );
}
