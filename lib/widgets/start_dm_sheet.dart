import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/create_room.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Starts a DM, asking for a user ID unless [userId] is given. Pops with true
/// if a DM was started.
class const StartDmSheet({final String? userId, final String? name, super.key})
    extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final userIdController = useTextEditingController();
    final text = useValueListenable(userIdController).text.trim();
    final target = userId ?? text;
    final valid = RegExp(r"^@[^:\s]+:[^\s]+$").hasMatch(target);
    final encrypted = useState(true);
    final reasonController = useTextEditingController();

    void submit() {
      if (!valid) return;
      context.startDirectMessage(
        target,
        name: name ?? target,
        encrypted: encrypted.value,
        inviteReason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );
      Navigator.of(context).pop(true);
    }

    return SheetLayout(
      title: const Text("Start a Direct Message"),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: valid ? submit : null,
          child: const Text("Start"),
        ),
      ],
      children: [
        if (userId == null)
          TextField(
            controller: userIdController,
            autofocus: true,
            keyboardType: .emailAddress,
            onSubmitted: (_) => submit(),
            decoration: .new(
              labelText: "User ID",
              hintText: "@user:example.com",
              errorText: text.isEmpty || valid ? null : "Enter a valid user ID",
            ),
          )
        else
          Text(
            "Are you sure you want to start a direct message with ${name ?? userId}?",
          ),
        TextField(
          controller: reasonController,
          textCapitalization: .sentences,
          onSubmitted: (_) => submit(),
          decoration: const .new(labelText: "Invite reason (optional)"),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.lock),
          title: const Text("Encrypted"),
          subtitle: const Text("Can't be turned off later"),
          value: encrypted.value,
          onChanged: (value) => encrypted.value = value,
        ),
      ],
    );
  }
}
