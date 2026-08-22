import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "spec_versions_response.freezed.dart";
part "spec_versions_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const SpecVersionsResponse({
  required final IList<String> versions,
  required final UnstableFeatures unstableFeatures,
}) with _$SpecVersionsResponse {
  Map<String, Object?> toJson() => _$SpecVersionsResponseToJson(this);

  factory SpecVersionsResponse.fromJson(Map<String, Object?> json) =>
      _$SpecVersionsResponseFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const UnstableFeatures({
  @JsonKey(name: "uk.timedout.msc4494") final bool msc4494 = false,
}) with _$UnstableFeatures {
  Map<String, Object?> toJson() => _$UnstableFeaturesToJson(this);

  factory UnstableFeatures.fromJson(Map<String, Object?> json) =>
      _$UnstableFeaturesFromJson(json);
}
