import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/secure_storage_controller.dart";

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ElevatedButton(
        onPressed: ref.watch(SecureStorageController.provider.notifier).clear,
        child: Text("Log out"),
      ),
    );
  }
}
