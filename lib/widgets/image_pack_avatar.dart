import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/mxc_emoji.dart";

class const ImagePackAvatar(final Uri? icon, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 40,
    child: switch (icon) {
      final icon? => MxcEmoji(icon),
      null => Icon(Icons.emoji_emotions),
    },
  );
}
