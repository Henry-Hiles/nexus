import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/events_decrypted.dart";
import "package:nexus/models/sync_data.dart";
import "package:nexus/models/sync_status.dart";
import "package:nexus/models/typing.dart";

part "gomuks_event.freezed.dart";

@freezed
sealed class GomuksEvent with _$GomuksEvent {
  const factory GomuksEvent.clientState(ClientState state) = ClientStateEvent;
  const factory GomuksEvent.syncStatus(SyncStatus status) = SyncStatusEvent;
  const factory GomuksEvent.initComplete() = InitCompleteEvent;
  const factory GomuksEvent.sendComplete(Event event) = SendCompleteEvent;
  const factory GomuksEvent.typing(Typing typing) = TypingEvent;
  const factory GomuksEvent.eventsDecrypted(EventsDecrypted decrypted) =
      EventsDecryptedEvent;
  const factory GomuksEvent.syncComplete(SyncData sync) = SyncCompleteEvent;
  const factory GomuksEvent.unknown(String type) = UnknownGomuksEvent;

  factory GomuksEvent.parse(String type, Map<String, dynamic> json) =>
      switch (type) {
        "client_state" => .clientState(.fromJson(json)),
        "sync_status" => .syncStatus(.fromJson(json)),
        "init_complete" => const .initComplete(),
        "send_complete" => .sendComplete(.fromJson(json["event"])),
        "typing" => .typing(.fromJson(json)),
        "events_decrypted" => .eventsDecrypted(.fromJson(json)),
        "sync_complete" => .syncComplete(.fromJson(json)),
        _ => .unknown(type),
      };
}
