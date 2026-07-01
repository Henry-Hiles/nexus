import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/models/setting.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (_, constraints) => HookBuilder(
      builder: (context) {
        final IMap<String, IList<SettingsCategory>>
        settingsCategoryGroups = .new({
          "General": .new([
            .new(
              title: "Appearance",
              icon: Icons.brush,
              settings: .new([
                Setting<ThemeMode>(
                  id: "dark_mode",
                  title: "Dark Mode",
                  initialValue: ThemeMode.system,
                  description:
                      "Toggle between Light Mode, Dark Mode, and System themes.",
                  builder: (title, description, onChanged, currentValue) =>
                      DialogListTile<ThemeMode>(
                        icon: Icon(Icons.palette),
                        title: title,
                        subtitle: Text(description),
                        initialValue: currentValue,
                        options: ThemeMode.values,
                        getName: (option) =>
                            toBeginningOfSentenceCase(option.name),
                        onChanged: onChanged,
                      ),
                ),
                Setting<bool>(
                  id: "use_csd",
                  initialValue: true,
                  title: "Use Client Side Decorations",
                  description:
                      "On desktop, toggle between client-side or server-side decorations",
                  builder: (title, description, onChanged, currentValue) =>
                      SwitchListTile(
                        title: Text(title),
                        secondary: Icon(Icons.border_top),
                        subtitle: Text(description),
                        value: currentValue,
                        onChanged: onChanged,
                      ),
                ),
                Setting<bool>(
                  id: "use_system_font",
                  title: "Use System Font",
                  initialValue: true,
                  description:
                      "Use the system's sans and emoji fonts, instead of Flutter's bundled fonts. Turn this off if you are having issues rendering emoji.",
                  builder: (title, description, onChanged, currentValue) =>
                      SwitchListTile(
                        title: Text(title),
                        subtitle: Text(description),
                        secondary: Icon(Icons.abc),
                        value: currentValue,
                        onChanged: onChanged,
                      ),
                ),
              ]),
            ),
          ]),
        });

        final categoriesArePages = constraints.maxWidth < 550;

        final selected = useState(0);

        final searchBar = SearchAnchor.bar(
          barHintText: "Search...",
          suggestionsBuilder: (context, controller) {
            // TODO
            return [];
          },
        );

        final settingsContent = Scaffold(
          appBar: AppBar(
            title: Text("Settings"),
            actionsPadding: .symmetric(horizontal: 12),
          ),
          body: categoriesArePages
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(12).copyWith(bottom: 8),
                        child: searchBar,
                      ),
                    ),
                    ...settingsCategoryGroups
                        .mapTo(
                          (categoryGroup, categories) => [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ).copyWith(bottom: 4),
                                child: DividerText(categoryGroup),
                              ),
                            ),
                            SliverM3ECardList(
                              padding: .symmetric(horizontal: 4, vertical: 8),
                              margin: .symmetric(horizontal: 12),
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              itemCount: categories.length,
                              onTap: (index) => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(categories[index].title),
                                    ),
                                    body: ListView(),
                                  ),
                                ),
                              ),
                              itemBuilder: (context, index) => ListTile(
                                leading: Icon(categories[index].icon),
                                title: Text(categories[index].title),
                              ),
                            ),
                          ],
                        )
                        .flattened,
                  ],
                )
              : Row(
                  children: [
                    NavigationRailM3E(
                      type: .alwaysExpand,
                      trailing: searchBar,
                      scrollable: true,
                      sections: settingsCategoryGroups
                          .mapTo(
                            (categoryGroup, categories) =>
                                NavigationRailM3ESection(
                                  header: DividerText(categoryGroup),
                                  destinations: categories
                                      .map(
                                        (category) =>
                                            NavigationRailM3EDestination(
                                              icon: Icon(category.icon),
                                              label: category.title,
                                            ),
                                      )
                                      .toList(),
                                ),
                          )
                          .toList(),
                      selectedIndex: selected.value,
                      onDestinationSelected: (value) => selected.value = value,
                    ),
                    VerticalDivider(),
                    Expanded(
                      child: SuperListView(
                        padding: .symmetric(vertical: 12),
                        children: settingsCategoryGroups
                            .values
                            .flattenedToList[selected.value]
                            .settings
                            .map(
                              (setting) => Padding(
                                padding: .only(bottom: 4),
                                child: setting.builder(
                                  setting.title,
                                  setting.description,
                                  (value) {},
                                  setting.initialValue,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
        );

        return constraints.maxWidth < 650
            ? settingsContent
            : Dialog(
                constraints: .loose(Size(900, 600)),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(12),
                  child: settingsContent,
                ),
              );
      },
    ),
  );
}
