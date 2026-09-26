import "package:freezed_annotation/freezed_annotation.dart";

enum Direction {
  @JsonValue("f")
  forward,
  @JsonValue("b")
  backward,
}
