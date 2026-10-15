import "package:material_ui/material_ui.dart";

extension WithProgressSnackbar on BuildContext {
  /// Shows [progress] in a snackbar while [action] runs, and shows any error
  /// it throws in an error snackbar.
  ///
  /// Returns the result of [action], or null if it failed.
  Future<T?> withProgressSnackbar<T>(
    String progress,
    Future<T> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(this);
    final colorScheme = Theme.of(this).colorScheme;

    final snackbar = messenger.showSnackBar(
      .new(content: Text(progress), duration: const .new(days: 1)),
    );

    try {
      return await action();
    } catch (error) {
      messenger.showSnackBar(
        .new(
          backgroundColor: colorScheme.errorContainer,
          content: Text(
            error.toString(),
            style: .new(color: colorScheme.onErrorContainer),
          ),
        ),
      );

      return null;
    } finally {
      snackbar.close();
    }
  }
}
