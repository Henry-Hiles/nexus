import "package:flutter_riverpod/flutter_riverpod.dart";

class NotificationRequestController extends Notifier<int?> {
  @override
  int? build() => null;

  void request(int rowId) => state = rowId;

  void consume() => state = null;

  static final provider = NotifierProvider<NotificationRequestController, int?>(
    NotificationRequestController.new,
  );
}
