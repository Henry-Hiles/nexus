import "package:freezed_annotation/freezed_annotation.dart";

class MSDuration implements JsonConverter<Duration, int> {
  const MSDuration();

  @override
  Duration fromJson(int ms) => Duration(milliseconds: ms);

  @override
  int toJson(Duration duration) => duration.inMilliseconds;
}
