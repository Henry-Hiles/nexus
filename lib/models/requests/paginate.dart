import "package:freezed_annotation/freezed_annotation.dart";

part "paginate.freezed.dart";
part "paginate.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PaginateRequest({
  required final String roomId,
  required final int? maxTimelineId,
  final int limit = 20,
}) with _$PaginateRequest {
  Map<String, Object?> toJson() => _$PaginateRequestToJson(this);

  factory PaginateRequest.fromJson(Map<String, Object?> json) =>
      _$PaginateRequestFromJson(json);
}
