import "dart:math";

import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "poll_start.freezed.dart";
part "poll_start.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const PollStartContent({
  @JsonKey(name: "org.matrix.msc3381.poll.start") required final PollStart poll,
}) extends Content with _$PollStartContent {
  @override
  Map<String, Object?> toJson() => {
    "org.matrix.msc3381.poll.start": poll.toJson(),
    // Shown by clients without poll support
    "org.matrix.msc1767.text": [
      poll.question,
      ...poll.answers.mapIndexed(
        (index, answer) => "${index + 1}. ${answer.text}",
      ),
    ].join("\n"),
  };

  factory PollStartContent.fromJson(Map<String, Object?> json) =>
      _$PollStartContentFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable()
class const PollStart({
  @JsonKey(readValue: PollStart.questionFromJson) final String question = "",
  final int? maxSelections,
  @JsonKey(readValue: PollStart.answersFromJson)
  final IList<PollAnswer> answers = const .empty(),
}) with _$PollStart {
  static const maxAnswers = 20;

  static String? extensibleTextFromJson(Object? json) => switch (json) {
    {"org.matrix.msc1767.text": final String text} => text,
    {"body": final String body} => body,
    {"org.matrix.msc1767.message": final List message} =>
      message
          .whereType<Map>()
          .map((part) => part["body"])
          .whereType<String>()
          .firstOrNull,
    _ => null,
  };

  static String? questionFromJson(Map<dynamic, dynamic> json, String key) =>
      PollStart.extensibleTextFromJson(json[key]);

  static List<dynamic>? answersFromJson(
    Map<dynamic, dynamic> json,
    String key,
  ) => (json[key] as List?)?.take(maxAnswers).toList();

  /// [maxSelections], defaulting to 1, and at most the number of answers
  int get selectionLimit =>
      (maxSelections ?? 1).clamp(1, max(answers.length, 1));

  Map<String, Object?> toJson() => {
    ..._$PollStartToJson(this),
    // We don't allow undisclosed polls as they make no sense
    "kind": "org.matrix.msc3381.poll.disclosed",
    "question": {"org.matrix.msc1767.text": question},
    "answers": answers.map((answer) => answer.toJson()).toList(),
  };

  factory PollStart.fromJson(Map<String, Object?> json) =>
      _$PollStartFromJson(json);
}

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const PollAnswer({
  required final String id,
  @JsonKey(readValue: PollAnswer.textFromJson) final String text = "",
}) with _$PollAnswer {
  static String? textFromJson(Map<dynamic, dynamic> json, _) =>
      PollStart.extensibleTextFromJson(json);

  Map<String, Object?> toJson() => {"id": id, "org.matrix.msc1767.text": text};

  factory PollAnswer.fromJson(Map<String, Object?> json) =>
      _$PollAnswerFromJson(json);
}
