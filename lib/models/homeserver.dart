import "package:freezed_annotation/freezed_annotation.dart";
part "homeserver.freezed.dart";

@freezed
abstract class Homeserver with _$Homeserver {
  const factory Homeserver({
    required String name,
    required String description,
    required Uri url,
    required String iconUrl,
  }) = _Homeserver;
}
