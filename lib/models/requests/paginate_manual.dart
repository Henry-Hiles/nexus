import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/direction.dart";

part "paginate_manual.freezed.dart";
part "paginate_manual.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PaginateManualRequest({
  required final String roomId,
  // Root event ID of a thread to paginate
  final String? threadRoot,
  // Can be null for starting pagination of a thread
  final String? since,
  required final Direction direction,
  final int limit = 20,
}) with _$PaginateManualRequest {
  Map<String, Object?> toJson() => _$PaginateManualRequestToJson(this);

  factory PaginateManualRequest.fromJson(Map<String, Object?> json) =>
      _$PaginateManualRequestFromJson(json);
}
