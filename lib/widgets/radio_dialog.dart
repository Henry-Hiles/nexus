import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class RadioDialog<T> extends HookWidget {
  final T? value;
  final String title;
  final List<T> options;
  final void Function(T value)? onChanged;
  final String Function(T option) getName;
  const RadioDialog({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.getName,
  });

  @override
  Widget build(BuildContext context) {
    final mutValue = useState<T?>(null);
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => RadioListTile<T>(
                value: option,
                groupValue: mutValue.value ?? value,
                onChanged: onChanged == null
                    ? null
                    : (value) =>
                          mutValue.value = value ?? mutValue.value ?? value,
                title: Text(getName(option)),
                dense: true,
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        if (onChanged != null)
          TextButton(
            onPressed: () {
              if (mutValue.value != null) onChanged!(mutValue.value as T);
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
      ],
    );
  }
}
