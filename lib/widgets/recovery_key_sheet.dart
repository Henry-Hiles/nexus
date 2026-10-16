import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/client.dart";
import "package:nexus/controllers/client_state.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/gomuks_exception.dart";
import "package:nexus/models/recovery_key.dart";
import "package:nexus/widgets/sheet_layout.dart";

/// Shows a newly generated recovery key, and once the user confirms they've
/// saved it, resets encryption with it. Pops with true if that succeeded.
class const RecoveryKeySheet(
  final RecoveryKey recoveryKey, {
  required final bool isReset,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = useState(false);
    final isLoading = useState(false);
    final error = useState<String?>(null);
    final needsApproval = useState(false);
    final approvalUrl = useState<Uri?>(null);
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> reset() async {
      if (isLoading.value) return;
      isLoading.value = true;
      error.value = null;
      try {
        await ref
            .read(ClientController.provider.notifier)
            .resetEncryption(recoveryKey);
        if (context.mounted) Navigator.of(context).pop(true);
      } catch (resetError) {
        if (resetError case GomuksException(statusCode: 401)) {
          // Open the approval page straight away the first time.
          if (!needsApproval.value) {
            needsApproval.value = true;
            final homeserver = ref
                .read(ClientStateController.provider)
                ?.homeserverUrl;
            final url = homeserver == null
                ? null
                : await ref
                      .read(ClientController.provider.notifier)
                      .getCrossSigningResetUrl(.parse(homeserver))
                      .onError((_, _) => null);
            if (!context.mounted || url == null) return;

            approvalUrl.value = url;
            await ref.read(LaunchHelper.provider).launchUrl(url);
          }
        } else {
          error.value = resetError.toString();
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    // Approval happens on a web page that can't redirect back, so keep retrying
    // in the background until it goes through, or the sheet is closed.
    useEffect(() {
      if (!needsApproval.value) return null;
      return Timer.periodic(const .new(seconds: 3), (_) => reset()).cancel;
    }, [needsApproval.value]);

    return SheetLayout(
      title: const Text("Save Your Recovery Key"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: !saved.value || isLoading.value ? null : reset,
          style: isReset
              ? TextButton.styleFrom(foregroundColor: colorScheme.error)
              : null,
          child: Text(
            needsApproval.value
                ? "Try Again"
                : isReset
                ? "Reset"
                : "Set Up",
          ),
        ),
      ],
      children: [
        const Text(
          "This is your new recovery key. Store it somewhere safe, like a password manager. You'll need it to verify new sessions.",
        ),
        Card.filled(
          child: ListTile(
            title: SelectableText(
              recoveryKey.recoveryKey,
              style: const .new(fontFamily: "bundled-mono"),
            ),
            trailing: IconButton(
              tooltip: "Copy recovery key",
              onPressed: () =>
                  Clipboard.setData(.new(text: recoveryKey.recoveryKey)),
              icon: const Icon(Icons.copy),
            ),
          ),
        ),
        CheckboxListTile(
          value: saved.value,
          onChanged: (value) => saved.value = value ?? false,
          title: const Text("I've saved my recovery key"),
        ),
        AnimatedSize(
          duration: Durations.medium2,
          curve: Curves.easeInOut,
          alignment: .topCenter,
          child: needsApproval.value
              ? Column(
                  crossAxisAlignment: .stretch,
                  spacing: 8,
                  children: [
                    const Text(
                      "Your homeserver needs you to approve resetting your identity in your account settings. Once you've approved it, come back here and the reset will finish automatically.",
                    ),
                    if (approvalUrl.value case final url?)
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(LaunchHelper.provider).launchUrl(url),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("Approve in account settings"),
                      ),
                  ],
                )
              : const SizedBox(width: .infinity),
        ),
        if (error.value case final message?)
          Text(message, style: .new(color: colorScheme.error)),
      ],
    );
  }
}
