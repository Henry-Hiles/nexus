import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/widgets/form_text_input.dart";

class VerifyPage extends HookConsumerWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passphraseController = useTextEditingController();
    return AlertDialog(
      title: Text("Verify"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your recovery key or passphrase below to unlock encrypted messages.\nYour passphrase is usually not the same as your password.",
          ),
          SizedBox(height: 12),
          FormTextInput(
            required: false,
            autofocus: true,
            capitalize: true,
            controller: passphraseController,
            obscure: true,
            title: "Recovery Key or Passphrase",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            ref
                .watch(ClientController.provider.notifier)
                .verify(passphraseController.text);
            Navigator.of(context).pop();
          },
          child: Text("Verify"),
        ),
      ],
    );
  }
}
