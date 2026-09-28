import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/event.dart";

class ContextualEventController(String? _) extends Notifier<Event?> {
  @override
  Event? build() => null;

  void set(Event? event) => state = event;

  @override
  bool updateShouldNotify(_, _) => true;

  static final provider = NotifierProvider.family
      .autoDispose<ContextualEventController, Event?, String?>(
        ContextualEventController.new,
      );
}
