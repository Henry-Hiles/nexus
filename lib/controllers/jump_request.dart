import "package:flutter_riverpod/flutter_riverpod.dart";

typedef JumpRequest = ({String roomId, int rowId});

class JumpRequestController extends Notifier<JumpRequest?> {
  @override
  JumpRequest? build() => null;

  void request(String roomId, int rowId) =>
      state = (roomId: roomId, rowId: rowId);

  void consume() => state = null;

  static final provider = NotifierProvider<JumpRequestController, JumpRequest?>(
    JumpRequestController.new,
  );
}
