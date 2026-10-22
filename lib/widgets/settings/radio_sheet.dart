import "package:material_ui/material_ui.dart";
import "package:nexus/widgets/sheet_layout.dart";
import "package:flutter_hooks/flutter_hooks.dart";

final class const RadioSheet<T>({
  required final T? value,
  required final String title,
  required final List<T> options,
  required final void Function(T value)? onChanged,
  required final String Function(T option) getName,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // Wrapped, so a null option can be chosen, rather than counting as nothing being chosen yet
    final chosen = useState<(T,)?>(null);
    return SheetLayout(
      title: Text(title),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        if (onChanged != null)
          TextButton(
            onPressed: () {
              if (chosen.value case (final picked,)) onChanged!(picked);
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
      ],
      children: [
        RadioGroup<T>(
          groupValue: switch (chosen.value) {
            (final picked,) => picked,
            null => value,
          },
          onChanged: (value) => chosen.value = (value as T,),

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
      ],
    );
  }
}
