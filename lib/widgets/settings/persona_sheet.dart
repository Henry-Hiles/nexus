import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_adaptive_sheets/material_adaptive_sheets.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/account_data.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/main.dart";
import "package:nexus/models/per_message_profiles.dart";
import "package:nexus/widgets/avatars/avatar_or_hash.dart";
import "package:nexus/widgets/avatars/editable_avatar.dart";

class const PersonaSheet({final StoredProfile? persona, super.key})
    extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = Saving.use();
    final trigger = persona?.triggers.firstOrNull;
    final nameController = useTextEditingController(text: persona?.displayName);
    final prefixController = useTextEditingController(text: trigger?.prefix);
    final suffixController = useTextEditingController(text: trigger?.suffix);
    final avatar = useState(persona?.avatarUrl);
    final name = useValueListenable(nameController).text.trim();

    final accountData = ref.read(AccountDataController.provider.notifier);
    PerMessageProfiles current() =>
        ref.read(AccountDataController.provider).perMessageProfiles;

    Future<void> update(PerMessageProfiles profiles) async {
      await saving.run(() => accountData.setPerMessageProfiles(profiles));
      if (context.mounted) Navigator.of(context).pop();
    }

    Future<void> save() {
      final prefix = prefixController.text;
      final suffix = suffixController.text;
      final edited = StoredProfile(
        id:
            persona?.id ??
            DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        displayName: name,
        avatarUrl: avatar.value,
        triggers: .new([
          if (prefix.isNotEmpty || suffix.isNotEmpty)
            (trigger ?? const .new()).copyWith(prefix: prefix, suffix: suffix),
          ...?persona?.triggers.skip(1),
        ]),
      );
      final profiles = current();

      return update(
        profiles.copyWith(
          profiles: persona == null
              ? profiles.profiles.add(edited)
              : profiles.profiles.replaceFirstWhere(
                  (profile) => profile.id == persona!.id,
                  (_) => edited,
                ),
        ),
      ).onError(showError);
    }

    Future<void> delete() {
      final profiles = current();
      return update(
        profiles.copyWith(
          profiles: profiles.profiles.removeWhere(
            (profile) => profile.id == persona!.id,
          ),
          defaultProfileId: profiles.defaultProfileId == persona!.id
              ? null
              : profiles.defaultProfileId,
        ),
      ).onError(showError);
    }

    return SheetLayout(
      title: Text(persona == null ? "Add Persona" : "Edit Persona"),
      actions: [
        if (persona != null)
          TextButton(
            onPressed: saving.active ? null : delete,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text("Delete"),
          ),
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        TextButton(
          onPressed: name.isEmpty || saving.active ? null : save,
          child: Text("Save"),
        ),
      ],
      children: [
        Center(
          child: EditableAvatar(
            dimension: 120,
            hasAvatar: avatar.value != null,
            onChanged: (url) async => avatar.value = url,
            child: AvatarOrHash(
              avatar.value,
              name.isEmpty ? "Persona" : name,
              dimension: 120,
            ),
          ),
        ),
        TextField(
          controller: nameController,
          autofocus: persona == null,
          textCapitalization: .words,
          decoration: const .new(labelText: "Display name"),
        ),
        Text(
          "Optionally, messages that start with the prefix *and* end with the suffix are sent as this persona, without them. Leave one empty to only need the other. Both are case-sensitive.",
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: TextField(
                controller: prefixController,
                decoration: const .new(
                  labelText: "Prefix",
                  hintText: "e.g. k:",
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: suffixController,
                decoration: const .new(labelText: "Suffix"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
