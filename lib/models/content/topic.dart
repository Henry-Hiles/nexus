import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";

part "topic.freezed.dart";
part "topic.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const TopicContent({
  required final String topic,
  @JsonKey(name: "m.topic") final TopicContentBlock? content,
}) extends Content with _$TopicContent {
  @override
  Map<String, Object?> toJson() => _$TopicContentToJson(this);

  factory TopicContent.fromJson(Map<String, Object?> json) =>
      _$TopicContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const TopicContentBlock({
  final IList<TextualRepresentation> representations = const .empty(),
}) with _$TopicContentBlock {
  Map<String, Object?> toJson() => _$TopicContentBlockToJson(this);

  factory TopicContentBlock.fromJson(Map<String, Object?> json) =>
      _$TopicContentBlockFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const TextualRepresentation({
  required final String body,
  final String mimetype = "text/plain",
}) with _$TextualRepresentation {
  Map<String, Object?> toJson() => _$TextualRepresentationToJson(this);

  factory TextualRepresentation.fromJson(Map<String, Object?> json) =>
      _$TextualRepresentationFromJson(json);
}
