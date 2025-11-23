import "package:color_hash/color_hash.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";

class AvatarOrHash extends StatelessWidget {
  final Uri? avatar;
  final String title;
  final Widget? fallback;
  final bool hasBadge;
  final double height;
  final Map<String, String> headers;
  const AvatarOrHash(
    this.avatar,
    this.title, {
    this.fallback,
    this.hasBadge = false,
    this.height = 24,
    required this.headers,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final box = ColoredBox(
      color: ColorHash(title).color,
      child: Center(child: Text(title[0])),
    );
    return SizedBox(
      width: height,
      height: height,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          child: Badge(
            isLabelVisible: hasBadge,
            smallSize: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: SizedBox(
              width: height,
              height: height,
              child: avatar == null
                  ? fallback ?? box
                  : Image.network(
                      avatar.toString(),
                      headers: headers,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => box,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
