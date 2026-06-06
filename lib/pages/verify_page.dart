import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/helpers/required_validator_helper.dart";

class VerifyPage extends HookConsumerWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passphraseController = useTextEditingController();
    final isLoading = useState(false);
    final inputError = useState<String?>(null);
    final formKey = useRef(GlobalKey<FormState>());

    Future<void> verify() async {
      isLoading.value = true;

      try {
        if (formKey.value.currentState?.validate() != true) {
          return;
        }

        inputError.value = await ref
            .watch(ClientController.provider.notifier)
            .verify(passphraseController.text);
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: Appbar(),
      body: AlertDialog(
        title: Text("Verify"),
        content: Form(
          key: formKey.value,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Text(
                "Enter your recovery key or passphrase below to unlock encrypted events.\nYour passphrase is usually not the same as your password.",
              ),
              SizedBox(height: 12),
              TextFormField(
                autofocus: true,
                controller: passphraseController,
                textInputAction: .done,
                autovalidateMode: .onUserInteraction,
                validator: requiredValidator,
                obscureText: true,
                decoration: .new(
                  label: Text("Recovery Key or Passphrase"),
                  errorText: inputError.value,
                ),
                onFieldSubmitted: (_) => verify(),
                // Don't defocus on submit
                onEditingComplete: () {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading.value ? null : verify,
            child: Text("Verify"),
          ),
        ],
      ),
    );
  }
}
