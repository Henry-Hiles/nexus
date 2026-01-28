import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";
import "package:nexus/models/event.dart";

extension ListToMessages on IList<Event> {
  Future<List<Message>> toMessages(ClientController client) async =>
      (await Future.wait(
        map((event) => event.toMessage(client)),
      )).nonNulls.toList();
}
