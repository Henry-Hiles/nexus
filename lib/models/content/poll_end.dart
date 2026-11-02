import "package:nexus/models/content/content.dart";

class const PollEndContent() extends Content {
  factory PollEndContent.fromJson(Map<String, dynamic> json) =>
      const PollEndContent();

  @override
  Map<String, dynamic> toJson() => {
    "org.matrix.msc3381.poll.end": {},
    "org.matrix.msc1767.text": "Ended the poll",
  };
}
