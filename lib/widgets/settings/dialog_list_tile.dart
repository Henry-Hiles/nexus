import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/widgets/settings/radio_dialog.dart";

class DialogListTile<T> extends ConsumerWidget {
  final T? initialValue;
  final String title;
  final Widget? subtitle;
  final List<T> options;
  final bool required;
  final Icon icon;
  final void Function(T value)? onChanged;
  final String Function(T option) getName;
  const DialogListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    required this.getName,
    this.subtitle,
    this.required = true,
  });

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
          ),
        ),
      ),
    ),
  );
}
