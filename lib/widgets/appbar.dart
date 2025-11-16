import "dart:io";
import "package:flutter/material.dart";

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final Color? backgroundColor;
  final double? scrolledUnderElevation;
  final List<Widget> actions;
  const Appbar({
    super.key,
    this.title,
    this.backgroundColor,
    this.scrolledUnderElevation,
    this.leading,
    this.actions = const [],
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  AppBar build(BuildContext context) => AppBar(
    leading: leading,
    backgroundColor: backgroundColor,
    scrolledUnderElevation: scrolledUnderElevation,
    actionsPadding: EdgeInsets.symmetric(horizontal: 8),
    title: title,
    actions: [
      ...actions,
      if (!(Platform.isAndroid || Platform.isIOS))
        IconButton(onPressed: () => exit(0), icon: Icon(Icons.close)),
    ],
  );
}
