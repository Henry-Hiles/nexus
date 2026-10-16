import "package:material_ui/material_ui.dart";

extension ShowErrorSnackBar on ScaffoldMessengerState {
  /// Shows [message] in a snackbar styled as an error.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    ({String label, VoidCallback onPressed})? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showSnackBar(
      .new(
        backgroundColor: colorScheme.errorContainer,
        content: Text(
          message,
          style: .new(color: colorScheme.onErrorContainer),
        ),
        action: action == null
            ? null
            : .new(
                label: action.label,
                onPressed: action.onPressed,
                textColor: colorScheme.onErrorContainer,
              ),
      ),
    );
  }
}
