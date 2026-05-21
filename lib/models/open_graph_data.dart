import "package:freezed_annotation/freezed_annotation.dart";
part "open_graph_data.freezed.dart";
part "open_graph_data.g.dart";

@freezed
abstract class OpenGraphData with _$OpenGraphData {
  const factory OpenGraphData({
    @JsonKey(name: "og:title") required String? title,
    @JsonKey(name: "og:description") required String? description,
    @JsonKey(name: "og:image") required Uri? imageUrl,
    @JsonKey(name: "og:image:width") required double? width,
    @JsonKey(name: "og:image:height") required double? height,
  }) = _OpenGraphData;

  factory OpenGraphData.fromJson(Map<String, dynamic> json) =>
      _$OpenGraphDataFromJson(json);
}
