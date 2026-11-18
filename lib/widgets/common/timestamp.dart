import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/clock.dart";
import "package:timeago/timeago.dart";

class const Timestamp(final DateTime timestamp, {super.key})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: timestamp.toString(),
    child: Text(
      format(timestamp, clock: ref.watch(ClockController.provider)),
      maxLines: 1,
      overflow: .ellipsis,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.grey),
    ),
  );
}
