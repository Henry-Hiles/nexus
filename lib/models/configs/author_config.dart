import "package:flutter_chat_core/flutter_chat_core.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/room.dart";
part "author_config.freezed.dart";
part "author_config.g.dart";

@freezed
abstract class AuthorConfig with _$AuthorConfig {
  const factory AuthorConfig({required Message message, required Room room}) =
      _AuthorConfig;

  factory AuthorConfig.fromJson(Map<String, Object?> json) =>
      _$AuthorConfigFromJson(json);
}
