import "package:freezed_annotation/freezed_annotation.dart";

part "open_graph_data.freezed.dart";
part "open_graph_data.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const OpenGraphData({
  @JsonKey(name: "og:title") required final String? title,
  @JsonKey(name: "og:description") required final String? description,
  @JsonKey(name: "og:image") required final Uri? imageUrl,
  @JsonKey(name: "og:image:width") required final double? width,
  @JsonKey(name: "og:image:height") required final double? height,
}) with _$OpenGraphData {
  Map<String, Object?> toJson() => _$OpenGraphDataToJson(this);

  factory OpenGraphData.fromJson(Map<String, dynamic> json) =>
      _$OpenGraphDataFromJson(json);
}
