import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/main.dart";
import "package:nexus/widgets/recovery_key_sheet.dart";
import "package:nexus/widgets/sheet_layout.dart";

class const ResetEncryptionSheet({
  /// Whether this is shown as a page rather than in a sheet, in which case it
  /// can't be cancelled, and is replaced once encryption is set up.
  final bool isPage = false,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReset = ref.watch(
      ClientStateController.provider.select(
        (state) => state?.verificationState.hasCrossSigning ?? false,
      ),
    );

    final usePassphrase = useState(false);
    final passphraseController = useTextEditingController();
    final confirmationController = useTextEditingController();
    final passphrase = useValueListenable(passphraseController).text;
    final confirmation = useValueListenable(confirmationController).text;
    final mismatch = confirmation.isNotEmpty && confirmation != passphrase;
    final isLoading = useState(false);
    final error = useState<String?>(null);
    final colorScheme = Theme.of(context).colorScheme;

    return SheetLayout(
      title: Text(isReset ? "Reset Encryption Identity" : "Set Up Encryption"),
      actions: [
        if (!isPage)
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
        TextButton(
          onPressed:
              isLoading.value ||
                  (usePassphrase.value &&
                      (passphrase.isEmpty || passphrase != confirmation))
              ? null
              : () async {
                  isLoading.value = true;
                  error.value = null;
                  try {
                    final recoveryKey = await ref
                        .read(ClientController.provider.notifier)
                        .generateRecoveryKey(
                          passphrase: usePassphrase.value ? passphrase : "",
                        );
                    if (!context.mounted) return;

                    final done = await context.showAdaptiveSheet<bool>(
                      (_) => RecoveryKeySheet(recoveryKey, isReset: isReset),
                    );
                    if (done != true) return;
                    if (context.mounted && !isPage) Navigator.of(context).pop();

                    // Shown from the root navigator, because on the verify page,
                    // this is replaced by the chat once the session is verified.
                    navigatorKey.currentContext?.showAdaptiveSheet(
                      (context) => SheetLayout(
                        title: Text(
                          isReset ? "Identity Reset" : "Encryption Set Up",
                        ),
                        actions: [
                          TextButton(
                            onPressed: Navigator.of(context).pop,
                            child: const Text("Done"),
                          ),
                        ],
                        children: [
                          Text(
                            isReset
                                ? "Your encryption identity has been reset, and this session is verified. You'll need to verify your other sessions again."
                                : "Encryption is set up, and this session is verified. Use your recovery key to verify your other sessions.",
                          ),
                        ],
                      ),
                    );
                  } catch (generateError) {
                    error.value = generateError.toString();
                  } finally {
                    if (context.mounted) isLoading.value = false;
                  }
                },
          child: Text(isReset ? "Continue" : "Set Up"),
        ),
      ],
      children: [
        Text(
          isReset
              ? "This replaces your encryption identity with a new one. Your other sessions will need to be verified again, and any messages you can't currently decrypt may become unreadable."
              : "Set up encryption so you can verify your other sessions, and get back your encrypted messages if you lose access to this one.",
        ),
        Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.password),
              title: const Text("Use a passphrase"),
              subtitle: const Text("Optional, as well as your recovery key"),
              value: usePassphrase.value,
              onChanged: (value) => usePassphrase.value = value,
            ),
            AnimatedSize(
              duration: Durations.medium2,
              curve: Curves.easeInOut,
              alignment: .topCenter,
              child: usePassphrase.value
                  ? Padding(
                      padding: const .only(top: 12),
                      child: Column(
                        crossAxisAlignment: .stretch,
                        spacing: 12,
                        children: [
                          const Text(
                            "Your passphrase can be used to gain access to your E2EE messages, so make it long and unique. Your passphrase should ideally not be the same as your password.",
                          ),
                          TextField(
                            controller: passphraseController,
                            obscureText: true,
                            decoration: const .new(labelText: "Passphrase"),
                          ),
                          TextField(
                            controller: confirmationController,
                            obscureText: true,
                            decoration: .new(
                              labelText: "Confirm passphrase",
                              errorText: mismatch
                                  ? "Passphrases don't match"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: .infinity),
            ),
          ],
        ),
        if (error.value case final message?)
          Text(message, style: .new(color: colorScheme.error)),
      ],
    );
  }
}
