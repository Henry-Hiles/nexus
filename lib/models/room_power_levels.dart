import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:nexus/models/content/power_levels.dart";

class const RoomPowerLevels({
  required final PowerLevelsContent content,
  final ISet<String> creators = const .empty(),
}) {
  double levelOf(String userId) => creators.contains(userId)
      ? double.infinity
      : (content.users[userId] ?? content.usersDefault).toDouble();

  bool canEndPoll(String userId, {required String pollSender}) =>
      userId == pollSender || levelOf(userId) >= content.redact;
}
