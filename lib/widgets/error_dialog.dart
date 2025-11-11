import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart";

class ErrorDialog extends ConsumerWidget {
  final Object error;
  final StackTrace? stackTrace;
  final ProviderOrFamily? provider;
  const ErrorDialog(this.error, this.stackTrace, {this.provider, super.key});

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
        TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text("Go Back"),
        ),
      ],
    );
  }
}
