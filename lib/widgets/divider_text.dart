import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/divider_widget.dart";

final class const DividerText(final String text, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      DividerWidget(Text(text, style: Theme.of(context).textTheme.labelLarge));
}
