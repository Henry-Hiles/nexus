import "package:material_ui/material_ui.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/widgets/appbar.dart";

class const NotificationsPage({final String? eventId, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: Appbar(title: Text("Notifications")),
      body: Placeholder(),
    );
  }
}
