import "package:freezed_annotation/freezed_annotation.dart";
part "paginate_request.freezed.dart";
part "paginate_request.g.dart";

@freezed
abstract class PaginateRequest with _$PaginateRequest {
  const factory PaginateRequest({
    required String roomId,
    required int? maxTimelineId,
    @Default(20) int limit,
  }) = _PaginateRequest;

  factory PaginateRequest.fromJson(Map<String, Object?> json) =>
      _$PaginateRequestFromJson(json);
}
