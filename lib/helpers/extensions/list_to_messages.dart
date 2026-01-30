import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";
import "package:nexus/models/event.dart";

extension ListToMessages on Iterable<Event> {
  Future<List<Message>> toMessages(Ref ref) async => (await Future.wait(
    map((event) => event.toMessage(ref)),
  )).nonNulls.toList();
}
