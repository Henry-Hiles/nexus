import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

abstract class const NavPage({super.key}) extends Widget {
  String get title;
  IconData get icon;
  Future<int>? badgeBuilder(WidgetRef ref) => null;
}
