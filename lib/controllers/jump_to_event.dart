import "package:flutter_riverpod/flutter_riverpod.dart";

class JumpToEventController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? eventId) => state = eventId;

  @override
  bool updateShouldNotify(_, _) => true;

  static final provider = NotifierProvider<JumpToEventController, String?>(
    JumpToEventController.new,
  );
}
