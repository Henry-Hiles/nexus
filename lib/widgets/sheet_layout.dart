import "package:material_ui/material_ui.dart";

class const SheetLayout({
  final Widget? title,
  required final List<Widget> children,
  required final List<Widget> actions,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: .only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (title case final title?)
          Padding(
            padding: const .fromLTRB(24, 24, 24, 0),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!,
              child: title,
            ),
          ),
        Flexible(
          child: SingleChildScrollView(
            padding: .fromLTRB(24, title == null ? 24 : 12, 24, 12),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              spacing: 12,
              children: children,
            ),
          ),
        ),
        Padding(
          padding: const .fromLTRB(24, 0, 24, 24),
          child: Row(mainAxisAlignment: .end, spacing: 8, children: actions),
        ),
      ],
    ),
  );
}
