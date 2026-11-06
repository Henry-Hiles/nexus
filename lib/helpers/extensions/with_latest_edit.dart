import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";

extension WithLatestEdit on Room {
  Event? withLatestEdit(int rowId) {
    final event = events[rowId];
    if (event == null) return null;

    final edited = event.lastEditRowId == 0
        ? null
        : events[event.lastEditRowId];

    return edited == null
        ? event
        : event.copyWith(
            content: edited.content,
            localContent: edited.localContent,
          );
  }
}
