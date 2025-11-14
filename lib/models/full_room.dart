import "package:freezed_annotation/freezed_annotation.dart";
import "package:matrix/matrix.dart";
part "full_room.freezed.dart";

@freezed
abstract class FullRoom with _$FullRoom {
  const factory FullRoom({
    required Room roomData,
    required String title,
    required Uri? avatar,
  }) = _FullRoom;
}
