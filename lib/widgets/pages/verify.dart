import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/models/client_state.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/widgets/loading.dart";
import "package:nexus/widgets/pages/settings.dart";
import "package:nexus/widgets/appbar.dart";
import "package:nexus/helpers/required_validator_helper.dart";
import "package:nexus/widgets/reset_encryption_sheet.dart";

class const VerifyPage({super.key}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passphraseController = useTextEditingController();
    final isLoading = useState(false);
    final inputError = useState<String?>(null);
    final formKey = useRef(GlobalKey<FormState>());

    final verificationState = ref.watch(
      ClientStateController.provider.select(
        (state) => state?.verificationState,
      ),
    );

    Future<void> verify() async {
      if (isLoading.value) return;

      if (formKey.value.currentState?.validate() != true) {
        return;
      }

      isLoading.value = true;

      try {
        await ref
            .read(ClientController.provider.notifier)
            .verify(passphraseController.text);
      } catch (error) {
        inputError.value = error.toString();
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
    }

    return Scaffold(
      appBar: Appbar(
        actions: .new([
          IconButton(
            onPressed: () =>
                showDialog(context: context, builder: (_) => SettingsPage()),
            icon: Icon(Icons.settings),
          ),
        ]),
      ),
      body: switch (verificationState) {
        null || VerificationState(stateChecked: false) => const Loading(),

        // Nothing to verify yet, so go straight to setup.
        VerificationState(hasSecretStorage: false) => Dialog(
          insetPadding: const .symmetric(vertical: 12, horizontal: 32),
          child: ConstrainedBox(
            constraints: const .new(maxWidth: 450),
            child: const ResetEncryptionSheet(isPage: true),
          ),
        ),

        _ => AlertDialog(
          insetPadding: .symmetric(vertical: 12, horizontal: 32),
          scrollable: true,
          title: Text("Verify"),
          content: Form(
            key: formKey.value,
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Text(
                  "Enter your recovery key or passphrase below to "
                  "unlock encrypted events.\nYour passphrase is usually "
                  "not the same as your password.",
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
              onPressed: isLoading.value
                  ? null
                  : () {
                      context.showAdaptiveSheet(
                        (_) => const ResetEncryptionSheet(),
                      );
                    },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text("Reset Identity"),
            ),
            TextButton(
              onPressed: isLoading.value ? null : verify,
              child: Text("Verify"),
            ),
          ],
        ),
      },
    );
  }
}
