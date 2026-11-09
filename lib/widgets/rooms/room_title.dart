import "package:material_ui/material_ui.dart";

/// A room or space's name, with its topic underneath if it has one, for app
/// bars.
class const RoomTitle(final String name, {final String? topic, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      Text(name, overflow: .ellipsis, maxLines: 1),
      if (topic?.isNotEmpty == true)
        Text(
          topic!,
          maxLines: 1,
          overflow: .ellipsis,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
    ],
  );
}
