import "package:color_hash/color_hash.dart";
import "package:flutter/widgets.dart";

class AvatarOrHash extends StatelessWidget {
  final Uri? avatar;
  final String title;
  final Widget? fallback;
  final Map<String, String> headers;
  const AvatarOrHash(
    this.avatar,
    this.title, {
    this.fallback,
    required this.headers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final box = ColoredBox(
      color: ColorHash(title).color,
      child: Center(child: Text(title[0])),
    );
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      child: SizedBox(
        width: 24,
        height: 24,
        child: avatar == null
            ? fallback ?? box
            : Image.network(
                avatar.toString(),
                headers: headers,
                errorBuilder: (_, _, _) => box,
              ),
      ),
    );
  }
}
