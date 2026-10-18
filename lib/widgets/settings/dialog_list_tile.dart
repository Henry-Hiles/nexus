import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/extensions/show_adaptive_sheet.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/settings/radio_sheet.dart";

final class const DialogListTile<T>({
  required final T? value,
  required final Icon icon,
  required final String title,
  required final List<T> options,
  required final void Function(T value)? onChanged,
  required final String Function(T option) getName,
  final Widget? subtitle,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    enabled: onChanged != null,
    onTap: () => context.showAdaptiveSheet(
      (context) => RadioSheet<T>(
        title: title,
        getName: getName,
        onChanged: onChanged,
        value: value,
        options: options,
      ),
    ),
    title: Text(title),
    subtitle: subtitle,
    leading: icon,
    trailing: Chip(
      label: Text(
        value == null ? "None" : getName(value as T),
        overflow: TextOverflow.ellipsis,
        style: onChanged == null ? .new(color: Colors.grey) : null,
      ),
    ),
  );
}
