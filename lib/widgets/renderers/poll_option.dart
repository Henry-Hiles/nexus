import "package:material_ui/material_ui.dart";

class const PollOption(
  final String text, {
  required final bool picked,
  required final bool isSingleChoice,

  /// From 0 to 1
  required final double share,
  final bool isWinner = false,
  final bool loading = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emphasis = isWinner ? const TextStyle(fontWeight: .bold) : null;

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 10,
      children: [
        Row(
          spacing: 12,
          children: [
            SizedBox.square(
              dimension: 20,
              child: loading
                  ? const CircularProgressIndicator(strokeWidth: 2.5)
                  : Icon(
                      switch ((isSingleChoice, picked)) {
                        (true, true) => Icons.radio_button_checked,
                        (true, false) => Icons.radio_button_unchecked,
                        (false, true) => Icons.check_box,
                        (false, false) => Icons.check_box_outline_blank,
                      },
                      size: 20,
                      color: picked
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
            ),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.merge(emphasis),
              ),
            ),
            Text(
              "${(share * 100).round()}%",
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant)
                  .merge(emphasis),
            ),
          ],
        ),
        TweenAnimationBuilder(
          tween: Tween(end: share),
          duration: Durations.medium2,
          curve: Curves.easeInOut,
          builder: (context, value, _) => LinearProgressIndicator(value: value),
        ),
      ],
    );
  }
}
