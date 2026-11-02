import "package:fast_immutable_collections/fast_immutable_collections.dart";

class const PollVotes({
  /// Each user's answers, by user ID
  final IMap<String, IList<String>> votes = const .empty(),
  final String? endEventId,
  final int undecryptable = 0,
}) {
  bool get hasEnded => endEventId != null;

  IMap<String, IList<String>> get votersByAnswer => votes.entries.fold(
    const .empty(),
    (acc, entry) => entry.value.fold(
      acc,
      (acc, answer) => acc.update(
        answer,
        (voters) => voters.add(entry.key),
        ifAbsent: () => .new([entry.key]),
      ),
    ),
  );

  int get voterCount =>
      votes.values.where((answers) => answers.isNotEmpty).length;
}
