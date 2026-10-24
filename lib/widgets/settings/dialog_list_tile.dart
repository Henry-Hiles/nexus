import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:nexus/helpers/hooks/saving.dart";
import "package:nexus/widgets/settings/radio_sheet.dart";

final class const DialogListTile<T>({
  required final T? value,
  required final Icon icon,
  required final String title,
  required final List<T> options,

  /// While a returned future runs, the tile is disabled.
  required final FutureOr<void> Function(T value)? onChanged,
  required final String Function(T option) getName,
  final Widget? subtitle,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final saving = Saving.use();
    Future<void> change(T value) => saving.run(() => onChanged!(value));

    return ListTile(
      enabled: onChanged != null && !saving.active,
      onTap: () => context.showAdaptiveSheet(
        (context) => RadioSheet<T>(
          title: title,
          getName: getName,
          onChanged: onChanged == null ? null : change,
          value: value,
          options: options,
        ),
      ),
      title: Text(title),
      subtitle: subtitle,
      leading: icon,
      trailing: ConstrainedBox(
        constraints: const .new(maxWidth: 160),
        child: Chip(
          label: Text(
            value is T ? getName(value as T) : "None",
            overflow: .ellipsis,
            style: onChanged == null || saving.active
                ? .new(color: Colors.grey)
                : null,
          ),
        ),
      ),
    );
  }
}
