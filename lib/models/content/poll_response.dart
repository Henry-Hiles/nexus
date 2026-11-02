import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:nexus/models/content/content.dart";
part "poll_response.freezed.dart";
part "poll_response.g.dart";

@Freezed(toJson: false, fromJson: false)
@JsonSerializable(createToJson: false)
class const PollResponseContent({
  @JsonKey(readValue: PollResponseContent.answersFromJson)
  final IList<String> answers = const .empty(),
}) extends Content with _$PollResponseContent {
  static List<dynamic>? answersFromJson(Map<dynamic, dynamic> json, _) =>
      json["org.matrix.msc3381.poll.response"]?["answers"];

  @override
  Map<String, Object?> toJson() => {
    "org.matrix.msc3381.poll.response": {"answers": answers.toList()},
  };

  factory PollResponseContent.fromJson(Map<String, Object?> json) =>
      _$PollResponseContentFromJson(json);
}
