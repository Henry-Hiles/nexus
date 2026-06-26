import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/models/settings_category.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/settings/dialog_list_tile.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static final IMap<String, IList<SettingsCategory>>
  settingsCategoryGroups = .new({
    "General": .new([
      .new(
        title: "Appearance",
        icon: Icons.brush,
        settings: .new([
          .new(
            title: "Dark Mode",
            description:
                "Toggle between Light Mode, Dark Mode, and System themes.",
            widget: DialogListTile<ThemeMode>(
              icon: Icon(Icons.palette),
              title: "Dark Mode",
              initialValue: ThemeMode.system,
              options: ThemeMode.values,
              getName: (option) => toBeginningOfSentenceCase(option.name),
              onChanged: (value) {},
            ),
          ),
          .new(
            title: "Use Client Side Decorations",
            description:
                "On desktop, toggle between client-side or server-side decorations",
            widget: SwitchListTile(
              title: Text("Client Side Decorations"),
              value: true,
              onChanged: (value) {},
            ),
          ),
        ]),
      ),
      .new(
        title: "Appearance",
        icon: Icons.brush,
        settings: .new([
          .new(
            title: "Dark Mode",
            description:
                "Toggle between Light Mode, Dark Mode, and System themes.",
            widget: DialogListTile<ThemeMode>(
              icon: Icon(Icons.palette),
              title: "Dark Mode",
              initialValue: ThemeMode.system,
              options: ThemeMode.values,
              getName: (option) => toBeginningOfSentenceCase(option.name),
              onChanged: (value) {},
            ),
          ),
          .new(
            title: "Use Client Side Decorations",
            description:
                "On desktop, toggle between client-side or server-side decorations",
            widget: SwitchListTile(
              title: Text("Client Side Decorations"),
              value: true,
              onChanged: (value) {},
            ),
          ),
        ]),
      ),
      .new(
        title: "Appearance",
        icon: Icons.brush,
        settings: .new([
          .new(
            title: "Dark Mode",
            description:
                "Toggle between Light Mode, Dark Mode, and System themes.",
            widget: DialogListTile<ThemeMode>(
              icon: Icon(Icons.palette),
              title: "Dark Mode",
              initialValue: ThemeMode.system,
              options: ThemeMode.values,
              getName: (option) => toBeginningOfSentenceCase(option.name),
              onChanged: (value) {},
            ),
          ),
          .new(
            title: "Use Client Side Decorations",
            description:
                "On desktop, toggle between client-side or server-side decorations",
            widget: SwitchListTile(
              title: Text("Client Side Decorations"),
              value: true,
              onChanged: (value) {},
            ),
          ),
        ]),
      ),
    ]),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (_, constraints) => HookBuilder(
      builder: (context) {
        final categoriesArePages = constraints.maxWidth < 550;

        final selected = useState(0);

        final settingsContent = Scaffold(
          appBar: AppBar(
            title: Text("Settings"),
            actionsPadding: .symmetric(horizontal: 12),
            actions: [
              SearchAnchor(
                builder: (_, controller) => IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: controller.openView,
                ),
                suggestionsBuilder: (context, controller) {
                  // TODO
                  return [];
                },
              ),
            ],
          ),
          body: categoriesArePages
              ? CustomScrollView(
                  slivers: settingsCategoryGroups
                      .mapTo(
                        (categoryGroup, categories) => [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ).copyWith(top: 8, bottom: 4),
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
                      .flattenedToList,
                )
              : Row(
                  children: [
                    NavigationRailM3E(
                      type: .alwaysExpand,
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
                        children: [
                          SwitchListTile(
                            title: Text("Settings Title"),
                            value: false,
                            onChanged: (value) {},
                          ),
                          SwitchListTile(
                            title: Text("Settings Title"),
                            value: false,
                            onChanged: (value) {},
                          ),
                          SwitchListTile(
                            title: Text("Settings Title"),
                            value: false,
                            onChanged: (value) {},
                          ),
                          SwitchListTile(
                            title: Text("Settings Title"),
                            value: false,
                            onChanged: (value) {},
                          ),
                          SwitchListTile(
                            title: Text("Settings Title"),
                            value: false,
                            onChanged: (value) {},
                          ),
                        ],
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
