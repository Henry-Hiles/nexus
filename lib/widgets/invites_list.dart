import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/models/nav_page.dart";

class const InvitesList({super.key})
    extends StatelessWidget
    implements NavPage {
  @override
  String get title => "Invites";

  @override
  IconData get icon => Icons.inbox;

  // TODO: Show notification badge here
  @override
  Future<int>? badgeBuilder(WidgetRef ref) => null;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
