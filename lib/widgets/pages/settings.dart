import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/settings_sections.dart";
import "package:nexus/helpers/extensions/show_about_sheet.dart";
import "package:nexus/widgets/settings/settings_layout.dart";

class const SettingsPage({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsLayout(
    title: "Settings",
    sectionsProvider: SettingsSectionsController.provider,
    actions: [
      IconButton(
        onPressed: () => context.showAboutSheet(ref),
        icon: Icon(Icons.info_outline),
      ),
    ],
  );
}
