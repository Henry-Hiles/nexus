import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:m3e_card_list/m3e_card_list.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";
import "package:nexus/controllers/settings_sections.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/show_about_dialog.dart";
import "package:nexus/pages/settings_category.dart";
import "package:nexus/widgets/divider_text.dart";
import "package:nexus/widgets/highlight_wrapper.dart";
import "package:super_sliver_list/super_sliver_list.dart";

class const SettingsPage({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (_, constraints) => HookBuilder(
      builder: (context) {
        final categoriesArePages = constraints.maxWidth < 550;

        final selected = useState(0);

        final highlightedMatch = useState<(int, int)?>(null);
        final listController = useRef(ListController());
        final scrollController = useScrollController();

        final searchBar = SearchAnchor.bar(
          barHintText: "Search...",
          isFullScreen: categoriesArePages,
          suggestionsBuilder: (suggestionsContext, controller) async {
            final categories = await ref.watch(
              SettingsSectionsController.provider.future,
            );
            final query = controller.text.toLowerCase();

            final matches = categories.values.flattenedToList
                .asMap()
                .entries
                .expand(
                  (categoryEntry) => categoryEntry.value.settings
                      .asMap()
                      .entries
                      .where(
                        (settingEntry) =>
                            settingEntry.value.title.toLowerCase().contains(
                              query,
                            ) ||
                            settingEntry.value.description
                                .toLowerCase()
                                .contains(query),
                      )
                      .map(
                        (settingEntry) => (
                          (categoryEntry.key, settingEntry.key),
                          settingEntry.value,
                        ),
                      ),
                )
                .toIList();

            return matches.map(
              (match) => ListTile(
                onTap: () async {
                  if (context.mounted) Navigator.of(suggestionsContext).pop();
                  controller.text = "";

                  if (categoriesArePages) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsCategoryPage(
                          match.$1.$1,
                          initialHighlight: match.$1.$2,
                        ),
                      ),
                    );
                  } else {
                    selected.value = match.$1.$1;
                    listController.value.animateToItem(
                      index: match.$1.$2,
                      scrollController: scrollController,
                      alignment: 0.5,
                      duration: (_) => .new(milliseconds: 700),
                      curve: (_) => Curves.easeInOut,
                    );
                    highlightedMatch.value = match.$1;
                    await Future.delayed(.new(seconds: 1), () {
                      if (highlightedMatch.value == match.$1) {
                        highlightedMatch.value = null;
                      }
                    });
                  }
                },
                leading: Icon(match.$2.icon),
                title: Text(match.$2.title),
                subtitle: Text(match.$2.description),
              ),
            );
          },
        );

        final settingsContent = Scaffold(
          appBar: AppBar(
            title: Text("Settings"),
            actionsPadding: .symmetric(horizontal: 12),
            actions: [
              IconButton(
                onPressed: () => context.showAboutDialog(ref),
                icon: Icon(Icons.info_outline),
              ),
            ],
          ),
          body: ref
              .watch(SettingsSectionsController.provider)
              .betterWhen(
                data: (sections) => categoriesArePages
                    ? CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(12).copyWith(bottom: 8),
                              child: searchBar,
                            ),
                          ),
                          ...sections
                              .mapTo(
                                (section, categories) => [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ).copyWith(bottom: 4),
                                      child: DividerText(section),
                                    ),
                                  ),
                                  SliverM3ECardList(
                                    padding: .symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    margin: .symmetric(horizontal: 12),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    itemCount: categories.length,
                                    onTap: (index) => Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SettingsCategoryPage(
                                                  sections
                                                      .values
                                                      .flattenedToList
                                                      .indexOf(
                                                        categories[index],
                                                      ),
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
                            sections: sections
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
                            onDestinationSelected: (value) =>
                                selected.value = value,
                          ),
                          VerticalDivider(),
                          Expanded(
                            child: SuperListView(
                              listController: listController.value,
                              controller: scrollController,
                              padding: .symmetric(vertical: 12),
                              children: sections
                                  .values
                                  .flattenedToList[selected.value]
                                  .settings
                                  .mapIndexed(
                                    (index, setting) => Padding(
                                      padding: .only(bottom: 4),
                                      child: HighlightWrapper(
                                        setting.builder(
                                          setting.title,
                                          setting.description,
                                          setting.icon,
                                        ),
                                        isHighlighted:
                                            highlightedMatch.value ==
                                            (selected.value, index),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
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
