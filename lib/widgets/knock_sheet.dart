import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/join_room.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Asks the moderators of a room to let the user in, with an optional reason.
///
/// Pops with true once the request has been sent.
class const KnockSheet(
  final String roomId, {
  required final String name,
  final IList<String> via = const .empty(),
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final reason = useTextEditingController();

    void onKnock() {
      context.knockRoom(
        .new(
          roomIdOrAlias: roomId,
          via: via,
          reason: reason.text.isEmpty ? null : reason.text,
        ),
        name: name,
      );
      Navigator.of(context).pop(true);
    }

    return SheetLayout(
      title: Text("Knock on $name"),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(onPressed: onKnock, child: Text("Knock")),
      ],
      children: [
        Text(
          "This room requires knocking to join. Its moderators will be able to see your knock and let you in.",
        ),
        TextField(
          textCapitalization: .sentences,
          controller: reason,
          decoration: .new(labelText: "Reason (optional)"),
          onEditingComplete: onKnock,
        ),
      ],
    );
  }
}
