import "package:flutter_riverpod/flutter_riverpod.dart";

class LaunchScopeController extends Notifier<bool> {
  @override
  bool build() => true;

  static final provider = NotifierProvider<LaunchScopeController, bool>(
    LaunchScopeController.new,
  );
}
