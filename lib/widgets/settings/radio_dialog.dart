import "package:material_ui/material_ui.dart";
import "package:flutter_hooks/flutter_hooks.dart";

final class const RadioDialog<T>({
  required final T? value,
  required final String title,
  required final List<T> options,
  required final void Function(T value)? onChanged,
  required final String Function(T option) getName,
  super.key,
}) extends HookWidget {
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
