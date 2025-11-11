import "package:color_hash/color_hash.dart";
import "package:flutter/widgets.dart";

class Avatar extends StatelessWidget {
  final Widget? avatar;
  final String title;
  final Widget? fallback;
  const Avatar(this.avatar, this.title, {this.fallback, super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    child: SizedBox(
      width: 24,
      height: 24,
      child:
          avatar ??
          fallback ??
          ColoredBox(
            color: ColorHash(title).color,
            child: Center(child: Text(title[0])),
          ),
    ),
  );
}
