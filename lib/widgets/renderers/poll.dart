import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_buttons/m3e_buttons.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:material_ui/material_ui.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/controllers/poll_votes.dart";
import "package:nexus/controllers/power_level.dart";
import "package:nexus/controllers/room_chat.dart";
import "package:nexus/controllers/room_power_levels.dart";
import "package:nexus/helpers/extensions/event_id_is_fake.dart";
import "package:nexus/main.dart";
import "package:nexus/models/content/poll_start.dart";
import "package:nexus/models/event.dart";
import "package:nexus/widgets/poll_option.dart";

class const PollRenderer(final Event event, final PollStart poll, {super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    /// The answer being voted for, or no answer while ending the poll
    final pending = useState<({String? answerId})?>(null);
    final isEnding = switch (pending.value) {
      (answerId: null) => true,
      _ => false,
    };

    final votesProvider = PollVotesController.provider(
      .new(roomId: event.roomId, eventRowId: event.rowId),
    );
    final votesState = ref.watch(votesProvider);
    final votes = votesState.value ?? const .new();
    final userId = ref.watch(
      ClientStateController.provider.select((value) => value?.userId),
    );
    final powerLevels = ref.watch(
      RoomPowerLevelsController.provider(event.roomId),
    );

    final isOpen = !event.eventId.isFake && !votes.hasEnded;
    final canVote =
        isOpen &&
        votesState.hasValue &&
        ref.watch(
          PowerLevelController.provider(
            .new(eventType: .pollResponse, roomId: event.roomId),
          ),
        );
    final canEnd =
        isOpen &&
        userId != null &&
        powerLevels.canEndPoll(userId, pollSender: event.sender);
    final ownVote =
        (userId == null ? null : votes.votes[userId]) ?? const .empty();
    final votersByAnswer = votes.votersByAnswer;
    final mostVotes =
        votersByAnswer.values.map((voters) => voters.length).maxOrNull ?? 0;
    final isSingleChoice = poll.selectionLimit == 1;

    final notifier = RoomChatController.provider((
      roomId: event.roomId,
      contextualEvent: null,
    )).notifier;

    Future<void> run(
      ({String? answerId}) action,
      Future<void> Function() send,
    ) async {
      pending.value = action;
      await send().onError(showError);
      if (!context.mounted) return;
      // Otherwise the old votes show until they're refetched
      await ref.read(votesProvider.future).onError((_, _) => const .new());
      if (context.mounted) pending.value = null;
    }

    Future<void> toggle(String answerId) {
      final picked = ownVote.contains(answerId)
          ? ownVote.remove(answerId)
          : isSingleChoice
          ? IList([answerId])
          : ownVote.add(answerId);

      return run(
        (answerId: answerId),
        () => ref
            .read(notifier)
            .votePoll(
              event,
              // Past the limit, the oldest pick is replaced
              picked.length > poll.selectionLimit ? picked.removeAt(0) : picked,
            ),
      );
    }

    void confirmEnd() => context.showAdaptiveSheet(
      (sheetContext) => SheetLayout(
        title: const Text("End Poll"),
        actions: [
          TextButton(
            onPressed: Navigator.of(sheetContext).pop,
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              run((answerId: null), () => ref.read(notifier).endPoll(event));
            },
            child: const Text("End"),
          ),
        ],
        children: const [
          Text(
            "Are you sure you want to end this poll? "
            "No one will be able to vote after it ends.",
          ),
        ],
      ),
    );

    final voterCount = votes.voterCount;

    return ConstrainedBox(
      constraints: const .new(maxWidth: 400),
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        spacing: 12,
        children: [
          Column(
            crossAxisAlignment: .start,
            spacing: 2,
            children: [
              Text(
                poll.question.isEmpty ? "Untitled poll" : poll.question,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                [
                  votes.hasEnded
                      ? "Ended"
                      : isSingleChoice
                      ? "Choose one"
                      : "Choose up to ${poll.selectionLimit}",
                  "$voterCount ${voterCount == 1 ? "vote" : "votes"}",
                ].join(" · "),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (votesState case AsyncError(:final error))
            Text(
              "Failed to load votes: $error",
              style: .new(color: colorScheme.error),
            ),
          if (votes.undecryptable case final count when count > 0)
            Row(
              spacing: 8,
              children: [
                Icon(Icons.lock, size: 16, color: colorScheme.error),
                Flexible(
                  child: Text(
                    "$count ${count == 1 ? "response" : "responses"} couldn't "
                    "be decrypted, so the results may be incomplete",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          M3ECardColumn(
            color: colorScheme.surface,
            outerRadius: 16,
            padding: const .symmetric(horizontal: 16, vertical: 12),
            onTap: canVote && pending.value == null
                ? (index) => toggle(poll.answers[index].id)
                : null,
            children: poll.answers.map((answer) {
              final count = votersByAnswer[answer.id]?.length ?? 0;

              return PollOption(
                answer.text,
                picked: ownVote.contains(answer.id),
                isSingleChoice: isSingleChoice,
                share: voterCount == 0 ? 0 : count / voterCount,
                isWinner: votes.hasEnded && count > 0 && count == mostVotes,
                loading: pending.value?.answerId == answer.id,
              );
            }).toList(),
          ),
          if (canEnd)
            Align(
              alignment: .centerRight,
              child: M3EButton.icon(
                style: .tonal,
                size: .xs,
                onPressed: pending.value == null ? confirmEnd : null,
                icon: isEnding
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_circle),
                label: const Text("End Poll"),
              ),
            ),
        ],
      ),
    );
  }
}
