import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:navigation_rail_m3e/navigation_rail_m3e.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Dialog(
    constraints: .loose(Size(900, 600)),
    child: ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(12),
      child: Scaffold(
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
                return [];
              },
            ),
          ],
        ),
        body: Padding(
          padding: .symmetric(vertical: 8),
          child: Row(
            children: [
              Padding(
                padding: .symmetric(vertical: 4),
                child: NavigationRailM3E(
                  type: .alwaysExpand,
                  sections: [
                    .new(
                      destinations: [
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                        .new(icon: Icon(Icons.abc), label: "Account"),
                      ],
                    ),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (value) {},
                ),
              ),
              VerticalDivider(),
            ],
          ),
        ),
      ),
    ),
  );
}
