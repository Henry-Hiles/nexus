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
      content: RadioGroup<T>(
        groupValue: mutValue.value ?? value,
        onChanged: (value) => mutValue.value = value ?? mutValue.value,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => RadioListTile<T>(
                  enabled: onChanged != null,
                  value: option,
                  title: Text(getName(option)),
                  dense: true,
                ),
              )
              .toList(),
        ),
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
