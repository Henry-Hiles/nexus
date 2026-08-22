import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/settings/radio_dialog.dart";

final class const DialogListTile<T>({
  required final T? initialValue,
  required final Icon icon,
  required final String title,
  required final List<T> options,
  required final void Function(T value)? onChanged,
  required final String Function(T option) getName,
  final Widget? subtitle,
  final bool required = true,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => FormField(
    validator: (value) =>
        value == null && required == true ? "This field is required." : null,
    initialValue: initialValue,
    builder: (field) => InputDecorator(
      decoration: InputDecoration(
        errorText: field.errorText,
        contentPadding: EdgeInsets.zero,
        enabledBorder: InputBorder.none,
      ),
      child: ListTile(
        enabled: onChanged != null,
        onTap: () => showDialog(
          context: context,
          builder: (context) => RadioDialog<T>(
            title: title,
            getName: getName,
            onChanged: onChanged == null
                ? null
                : (value) {
                    field.didChange(value);
                    onChanged!.call(value);
                  },
            value: field.value,
            options: options,
          ),
        ),
        title: Text(title),
        subtitle: subtitle,
        leading: icon,
        trailing: Chip(
          label: Text(
            field.value == null ? "None" : getName(field.value as T),
            overflow: TextOverflow.ellipsis,
            style: onChanged == null ? .new(color: Colors.grey) : null,
          ),
        ),
      ),
    ),
  );
}
