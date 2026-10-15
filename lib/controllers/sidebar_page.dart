import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/models/sidebar_page.dart";

class SidebarPageController extends Notifier<SidebarPage> {
  @override
  SidebarPage build() => .rooms;

  void set(SidebarPage page) => state = page;

  static final provider = NotifierProvider<SidebarPageController, SidebarPage>(
    SidebarPageController.new,
  );
}
