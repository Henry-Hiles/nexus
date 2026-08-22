import "package:material_ui/material_ui.dart";

class const Loading({super.key, final double? height}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: .all(16),
      child: SizedBox(height: height, child: CircularProgressIndicator()),
    ),
  );
}
