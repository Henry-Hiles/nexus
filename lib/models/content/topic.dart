import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "topic.freezed.dart";
part "topic.g.dart";

@freezed
abstract class TopicContent extends Content with _$TopicContent {
  TopicContent._();
  factory TopicContent({
    required String topic,
    @JsonKey(name: "m.topic") TopicContentBlock? content,
  }) = _TopicContent;

  factory TopicContent.fromJson(Map<String, Object?> json) =>
      _$TopicContentFromJson(json);
}

@freezed
abstract class TopicContentBlock with _$TopicContentBlock {
  factory TopicContentBlock({
    @Default(IList.empty())
    @JsonKey(name: "m.text")
    IList<TextualRepresentation> representations,
  }) = _TopicContentBlock;

  factory TopicContentBlock.fromJson(Map<String, Object?> json) =>
      _$TopicContentBlockFromJson(json);
}

@freezed
abstract class TextualRepresentation with _$TextualRepresentation {
  factory TextualRepresentation({
    required String body,
    @Default("text/plain") String mimetype,
  }) = _TextualRepresentation;

  factory TextualRepresentation.fromJson(Map<String, Object?> json) =>
      _$TextualRepresentationFromJson(json);
}
