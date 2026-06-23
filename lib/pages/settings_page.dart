import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text("Settings"),
      actionsPadding: .symmetric(horizontal: 12),
      actions: [
        SearchAnchor(
          builder: (context, controller) => IconButton(
            icon: const Icon(Icons.search),
            onPressed: controller.openView,
          ),
          suggestionsBuilder: (context, controller) {
            return [];
          },
        ),
      ],
    ),
  );
}
