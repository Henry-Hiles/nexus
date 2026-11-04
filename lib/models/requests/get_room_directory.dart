import "package:freezed_annotation/freezed_annotation.dart";

part "get_room_directory.freezed.dart";
part "get_room_directory.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class const GetRoomDirectoryRequest({
  final String? server,
  final int limit = 48,
  final String? since,
  final PublicRoomsFilter? filter,
}) with _$GetRoomDirectoryRequest {
  Map<String, Object?> toJson() => _$GetRoomDirectoryRequestToJson(this);

  factory GetRoomDirectoryRequest.fromJson(Map<String, Object?> json) =>
      _$GetRoomDirectoryRequestFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const PublicRoomsFilter({final String? genericSearchTerm})
    with _$PublicRoomsFilter {
  Map<String, Object?> toJson() => _$PublicRoomsFilterToJson(this);

  factory PublicRoomsFilter.fromJson(Map<String, Object?> json) =>
      _$PublicRoomsFilterFromJson(json);
}
