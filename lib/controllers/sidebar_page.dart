import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/notification_request.dart";
import "package:nexus/models/sidebar_page.dart";

class SidebarPageController extends Notifier<SidebarPage> {
  // Show the notification that switched accounts, if one did
  @override
  SidebarPage build() =>
      ref.read(NotificationRequestController.provider) == null
      ? .rooms
      : .notifications;

  void set(SidebarPage page) => state = page;

  static final provider = NotifierProvider<SidebarPageController, SidebarPage>(
    SidebarPageController.new,
  );
}
