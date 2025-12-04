import "package:freezed_annotation/freezed_annotation.dart";
import "package:matrix/matrix.dart";
part "full_room.freezed.dart";

@freezed
abstract class FullRoom with _$FullRoom {
  const FullRoom._();
  const factory FullRoom({
    required Room roomData,
    required String title,
    required Uri? avatar,
  }) = _FullRoom;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is FullRoom &&
      other.avatar == avatar &&
      other.title == title;

  @override
  int get hashCode => Object.hash(runtimeType, title, avatar);
}
