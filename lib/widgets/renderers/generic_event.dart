import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";

class const GenericEventRenderer(
  final IconData icon,
  final List<InlineSpan> children, {
  final int? maxLines,

  /// Shown at the end of the text, like the event's timestamp.
  final Widget? trailing,

  /// Shown under the text, like what changed in a state event.
  final List<Widget> details = const [],
  super.key,
}) extends StatelessWidget {
  static const _iconPadding = 4.0;
  static const _spacing = 8.0;

  /// How far the text is from the start, past the icon, so what's shown under
  /// the event can line up with it.
  static double textIndent(BuildContext context) =>
      (IconTheme.of(context).size ?? 24) + _iconPadding * 2 + _spacing;

  @override
  Widget build(BuildContext context) {
    // Only previewing the event, so it should stay short
    final previewing = maxLines != null;
    final iconSize = IconTheme.of(context).size ?? 24;

    return Padding(
      padding: .symmetric(vertical: 4),
      child: Row(
        spacing: _spacing,
        mainAxisSize: .min,
        // At the top, by the text, rather than the middle of any details
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .symmetric(horizontal: _iconPadding),
            child: Icon(icon),
          ),
          Flexible(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                // At least as tall as the icon, so they're centered together
                ConstrainedBox(
                  constraints: .new(minHeight: iconSize),
                  child: Row(
                    spacing: 8,
                    mainAxisSize: .min,
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: children
                                .expandIndexed(
                                  (index, child) => [
                                    if (index > 0) TextSpan(text: " "),
                                    child,
                                  ],
                                )
                                .toList(),
                          ),
                          maxLines: maxLines ?? 999,
                          overflow: .ellipsis,
                        ),
                      ),
                      if (!previewing) ?trailing,
                    ],
                  ),
                ),
                if (!previewing) ...details,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
