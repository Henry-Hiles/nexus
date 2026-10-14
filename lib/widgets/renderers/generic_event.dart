import "package:collection/collection.dart";
import "package:material_ui/material_ui.dart";

class const GenericEventRenderer(
  final IconData icon,
  final List<InlineSpan> children, {
  final int? maxLines,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: .symmetric(vertical: 4),
    child: Row(
      spacing: 8,
      mainAxisSize: .min,
      children: [
        Padding(padding: .symmetric(horizontal: 4), child: Icon(icon)),
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
      ],
    ),
  );
}
