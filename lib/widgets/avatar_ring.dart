import "package:material_ui/material_ui.dart";

class const AvatarRing({
  required final String tooltip,
  required final VoidCallback onTap,
  required final Widget child,
  final double dimension = 24,
  super.key,
}) extends StatelessWidget {
  static const ringWidth = 1.5;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Container(
      padding: .all(ringWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: .circle,
      ),
      child: ClipOval(
        child: SizedBox.square(
          dimension: dimension,
          child: Stack(
            fit: .expand,
            children: [
              child,
              // Over the child, so the ripple shows on top of avatars
              Material(
                type: .transparency,
                child: InkWell(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
