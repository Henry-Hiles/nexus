import "package:freezed_annotation/freezed_annotation.dart";

part "homeserver.freezed.dart";

@freezed
class const Homeserver({
  @override required final String name,
  @override required final String description,
  @override required final Uri url,
  @override required final String iconUrl,
}) with _$Homeserver;
