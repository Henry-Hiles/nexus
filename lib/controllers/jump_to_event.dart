import "package:flutter_riverpod/flutter_riverpod.dart";

class JumpToEventController(String? _) extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? eventId) => state = eventId;

  @override
  bool updateShouldNotify(_, _) => true;

  static final provider = NotifierProvider.family
      .autoDispose<JumpToEventController, String?, String?>(
        JumpToEventController.new,
      );
}
