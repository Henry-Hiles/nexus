import "package:flutter/material.dart";
import "package:timeago/timeago.dart";

class const Timestamp(final DateTime timestamp, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Tooltip(
    message: timestamp.toString(),
    child: Text(
      format(timestamp),
      maxLines: 1,
      overflow: .ellipsis,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.grey),
    ),
  );
}
