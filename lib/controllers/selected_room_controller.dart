import "package:flutter_riverpod/flutter_riverpod.dart";

class SelectedRoomController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;

  static final provider = NotifierProvider<SelectedRoomController, int>(
    SelectedRoomController.new,
  );
}
