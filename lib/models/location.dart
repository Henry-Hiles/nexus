import "package:freezed_annotation/freezed_annotation.dart";
import "package:latlong2/latlong.dart";
import "package:nexus/models/content/message.dart";

part "location.freezed.dart";
part "location.g.dart";

/// A location message's `m.location` block.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const LocationInfo({required final Uri uri, final String? description})
    with _$LocationInfo {
  Map<String, Object?> toJson() => _$LocationInfoToJson(this);

  factory LocationInfo.fromJson(Map<String, Object?> json) =>
      _$LocationInfoFromJson(json);
}

/// A location message's `m.asset` block.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const LocationAsset({
  @JsonKey(unknownEnumValue: LocationAssetType.pin)
  final LocationAssetType type = .self,
}) with _$LocationAsset {
  Map<String, Object?> toJson() => _$LocationAssetToJson(this);

  factory LocationAsset.fromJson(Map<String, Object?> json) =>
      _$LocationAssetFromJson(json);
}

enum LocationAssetType {
  @JsonValue("m.self")
  self,

  @JsonValue("m.pin")
  pin,
}

extension LocationMessagePoint on LocationMessageContent {
  LatLng? get point => location?.uri.latLng ?? geoUri.latLng;

  String? get description => switch (location?.description?.trim()) {
    final description? when description.isNotEmpty => description,
    _ => null,
  };

  LocationAssetType get assetType => asset?.type ?? .self;
}

extension FormatLatLng on LatLng {
  String get formatted =>
      "${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}";
}

extension GeoUri on Uri {
  /// The coordinates of a geo: URI, like `geo:51.5,-0.12;u=35`.
  LatLng? get latLng {
    if (scheme != "geo") return null;
    final coordinates = path.split(";").first.split(",");
    if (coordinates.length < 2) return null;

    return switch ((
      double.tryParse(coordinates[0]),
      double.tryParse(coordinates[1]),
    )) {
      (final latitude?, final longitude?)
          when latitude.abs() <= 90 && longitude.abs() <= 180 =>
        LatLng(latitude, longitude),
      _ => null,
    };
  }

  static Uri openStreetMap(LatLng point) => Uri.https(
    "www.openstreetmap.org",
    "/",
    {"mlat": "${point.latitude}", "mlon": "${point.longitude}"},
  ).replace(fragment: "map=16/${point.latitude}/${point.longitude}");

  static Uri fromLatLng(LatLng point, {double? uncertainty}) => Uri.parse(
    "geo:${point.latitude},${point.longitude}"
    "${uncertainty == null ? "" : ";u=${uncertainty.round()}"}",
  );
}
