import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/helpers/extensions/create_room.dart";
import "package:nexus/helpers/extensions/get_localpart.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const CreateRoomSheet({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverName = ref
        .watch(ClientStateController.provider)
        ?.userId
        ?.serverName;
    final nameController = useTextEditingController();
    final topicController = useTextEditingController();
    final aliasController = useTextEditingController();
    final name = useValueListenable(nameController).text.trim();
    final isPublic = useState(false);
    final isPublished = useState(false);
    final isEncrypted = useState(false);
    final isSpace = useState(false);

    void submit() {
      if (name.isEmpty) return;

      final topic = topicController.text.trim();
      final alias = aliasController.text.trim();

      context.createRoom(
        .new(
          name: name,
          topic: topic.isEmpty ? null : topic,
          roomAliasName: isPublic.value && alias.isNotEmpty ? alias : null,
          visibility: isPublic.value && isPublished.value ? .public : .private,
          preset: isPublic.value ? .publicChat : .privateChat,
          initialState: isEncrypted.value && !isSpace.value
              ? .new([.encryption])
              : const .empty(),
          creationContent: isSpace.value ? .new({"type": "m.space"}) : null,
        ),
        name: name,
      );
      Navigator.of(context).pop();
    }

    AnimatedSize animated({
      required bool visible,
      required Widget child,
      double gap = 12,
    }) => AnimatedSize(
      duration: Durations.medium2,
      curve: Curves.easeInOut,
      alignment: .topCenter,
      child: visible
          ? Padding(
              padding: .only(top: gap),
              child: child,
            )
          : const SizedBox(width: .infinity),
    );

    return SheetLayout(
      title: Text("Create a ${isSpace.value ? "Space" : "Room"}"),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: name.isEmpty ? null : submit,
          child: const Text("Create"),
        ),
      ],
      children: [
        TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: .sentences,
          onSubmitted: (_) => submit(),
          decoration: const .new(labelText: "Name"),
        ),
        TextField(
          controller: topicController,
          textCapitalization: .sentences,
          decoration: const .new(labelText: "Topic (optional)"),
        ),
        Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.public),
              title: const Text("Public"),
              subtitle: const Text("Anyone can join"),
              value: isPublic.value,
              onChanged: (value) {
                isPublic.value = value;
                if (value) isEncrypted.value = false;
              },
            ),
            animated(
              visible: isPublic.value,
              child: TextField(
                controller: aliasController,
                decoration: .new(
                  labelText: "Canonical alias (optional)",
                  prefixText: "# ",
                  suffixText: serverName == null ? null : ":$serverName",
                  hintText: "my-room",
                ),
              ),
            ),
            animated(
              visible: isPublic.value,
              child: SwitchListTile(
                secondary: const Icon(Icons.travel_explore),
                title: const Text("Publish to room directory"),
                subtitle: const Text("List it in your homeserver's directory"),
                value: isPublished.value,
                onChanged: (value) => isPublished.value = value,
              ),
            ),
          ],
        ),
        Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.workspaces),
              title: const Text("Space"),
              subtitle: const Text("A group of rooms"),
              value: isSpace.value,
              onChanged: (value) => isSpace.value = value,
            ),
            animated(
              visible: !isSpace.value,
              child: SwitchListTile(
                secondary: const Icon(Icons.lock),
                title: const Text("Encrypted"),
                subtitle: const Text("Can't be turned off later"),
                value: isEncrypted.value,
                onChanged: (value) => isEncrypted.value = value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
