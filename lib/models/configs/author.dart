import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/event.dart";

part "author.freezed.dart";

@freezed
class const AuthorConfig({
  required final String roomId,
  required final String userId,
  final Uri? avatarUrl,
  final String? displayName,
}) with _$AuthorConfig {
  factory AuthorConfig.fromEvent(Event event) => .new(
    roomId: event.roomId,
    userId: event.sender,
    avatarUrl: event.pmp?.avatarUrl,
    displayName: event.pmp?.displayName,
  );
}
