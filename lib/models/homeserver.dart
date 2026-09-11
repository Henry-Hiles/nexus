import "package:freezed_annotation/freezed_annotation.dart";

part "homeserver.freezed.dart";

@freezed
class const Homeserver({
  required final String name,
  required final String description,
  required final Uri url,
  required final String iconUrl,
}) with _$Homeserver;
