import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
part "spec_versions_response.freezed.dart";
part "spec_versions_response.g.dart";

@freezed
abstract class SpecVersionsResponse with _$SpecVersionsResponse {
  const factory SpecVersionsResponse({
    required IList<String> versions,
    required UnstableFeatures unstableFeatures,
  }) = _SpecVersionsResponse;

  factory SpecVersionsResponse.fromJson(Map<String, Object?> json) =>
      _$SpecVersionsResponseFromJson(json);
}

@freezed
abstract class UnstableFeatures with _$UnstableFeatures {
  const factory UnstableFeatures({
    @JsonKey(name: "uk.timedout.msc4494") @Default(false) bool msc4494,
  }) = _UnstableFeatures;

  factory UnstableFeatures.fromJson(Map<String, Object?> json) =>
      _$UnstableFeaturesFromJson(json);
}
