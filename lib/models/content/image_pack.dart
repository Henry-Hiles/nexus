import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
import "package:nexus/models/info/image.dart";
part "image_pack.freezed.dart";
part "image_pack.g.dart";

/// An image pack (MSC2545), from a room's state.
@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const ImagePackContent({
  final IMap<String, PackImage> images = const .empty(),
  final PackInfo? pack,
}) extends Content with _$ImagePackContent {
  /// Whether the pack has images or a name, as deleted packs are left empty.
  bool get hasContent => images.isNotEmpty || pack?.displayName != null;

  IMap<String, PackImage> imagesFor(ImageUsage usage) => images.where(
    (_, image) => switch ((image.usage, pack?.usage ?? const .empty())) {
      (final usages, _) when usages.isNotEmpty => usages.contains(usage),
      (_, final packUsages) when packUsages.isNotEmpty => packUsages.contains(
        usage,
      ),
      _ => true,
    },
  );

  @override
  Map<String, Object?> toJson() => _$ImagePackContentToJson(this);

  factory ImagePackContent.fromJson(Map<String, Object?> json) =>
      _$ImagePackContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const PackImage({
  required final Uri url,
  final String? body,
  final ImageInfo? info,
  @JsonKey(fromJson: ImageUsage.setFromJson, toJson: ImageUsage.setToJson)
  final ISet<ImageUsage> usage = const .empty(),
}) with _$PackImage {
  Map<String, Object?> toJson() => _$PackImageToJson(this);

  factory PackImage.fromJson(Map<String, Object?> json) =>
      _$PackImageFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(includeIfNull: false)
class const PackInfo({
  final String? displayName,
  final Uri? avatarUrl,
  final String? attribution,
  @JsonKey(fromJson: ImageUsage.setFromJson, toJson: ImageUsage.setToJson)
  final ISet<ImageUsage> usage = const .empty(),
}) with _$PackInfo {
  Map<String, Object?> toJson() => _$PackInfoToJson(this);

  factory PackInfo.fromJson(Map<String, Object?> json) =>
      _$PackInfoFromJson(json);
}

enum ImageUsage {
  emoticon,
  sticker;

  /// Ignores usages we don't know about.
  static ISet<ImageUsage> setFromJson(List<dynamic>? json) =>
      ISet(values.where((value) => json?.contains(value.name) ?? false));

  /// Omits an empty set, which means every usage.
  static List<String>? setToJson(ISet<ImageUsage> usages) =>
      usages.isEmpty ? null : usages.map((usage) => usage.name).toList();
}
