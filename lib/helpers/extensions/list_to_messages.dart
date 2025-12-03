import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:matrix/matrix.dart";
import "package:nexus/helpers/extensions/event_to_message.dart";

extension ListToMessages on List<MatrixEvent> {
  Future<List<Message>> toMessages(Room room) async {
    final messages = await Future.wait(
      map((event) => Event.fromMatrixEvent(event, room).toMessage()),
    );

    return {
      for (var msg in messages.nonNulls.toList().reversed.toList()) msg.id: msg,
    }.values.toList();
  }
}
