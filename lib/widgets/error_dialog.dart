import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";

final class const ErrorDialog(
  final Object error,
  final StackTrace? stackTrace, {
  final ProviderOrFamily? provider,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text("An Error Occurred"),
      content: SingleChildScrollView(
        child: SelectableText("$error\n\n$stackTrace"),
      ),
      actions: [
        if (provider != null)
          TextButton(
            onPressed: () => ref.invalidate(provider!),
            child: const Text("Try Again"),
          ),
        if (Navigator.of(context).canPop())
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text("Go Back"),
          ),
      ],
    );
  }
}
