import "package:material_ui/material_ui.dart";

class const SheetLayout({
  required final Widget title,
  required final List<Widget> children,
  required final List<Widget> actions,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: .only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const .all(24),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: 12,
        children: [
          DefaultTextStyle(
            style: Theme.of(context).textTheme.headlineSmall!,
            child: title,
          ),
          ...children,
          Row(mainAxisAlignment: .end, spacing: 8, children: actions),
        ],
      ),
    ),
  );
}
