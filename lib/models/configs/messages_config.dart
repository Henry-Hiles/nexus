import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";
import "package:nexus/models/room.dart";
part "messages_config.freezed.dart";
part "messages_config.g.dart";

@freezed
abstract class MessagesConfig with _$MessagesConfig {
  const factory MessagesConfig({
    required Room room,
    required IList<Event> events,
  }) = _MessagesConfig;

  factory MessagesConfig.fromJson(Map<String, Object?> json) =>
      _$MessagesConfigFromJson(json);
}
