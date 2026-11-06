import "package:freezed_annotation/freezed_annotation.dart";

part "get_threads.freezed.dart";
part "get_threads.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const GetThreadsRequest({
  required final String roomId,
  final String? since,
  final int limit = 20,
}) with _$GetThreadsRequest {
  Map<String, Object?> toJson() => _$GetThreadsRequestToJson(this);

  factory GetThreadsRequest.fromJson(Map<String, Object?> json) =>
      _$GetThreadsRequestFromJson(json);
}
