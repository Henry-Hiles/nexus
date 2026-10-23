import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";

/// A field for a power level, which can't be above the user's own.
class const PowerLevelField({
  required final TextEditingController controller,

  /// The user's own power level, which they can't set levels above.
  required final double ownLevel,
  final VoidCallback? onSubmitted,
  final bool autofocus = false,
  super.key,
}) extends HookWidget {
  /// The furthest from zero Matrix allows integers to be.
  static const maxMagnitude = (1 << 53) - 1;

  /// The level in [text], if it's one someone with [ownLevel] can set.
  static int? levelFrom(String text, double ownLevel) => switch (int.tryParse(
    text,
  )) {
    final level? when level.abs() <= maxMagnitude && level <= ownLevel => level,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final text = useValueListenable(controller).text;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: .numberWithOptions(signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"^-?\d*"))],
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      decoration: .new(
        labelText: "Power level",
        errorText: switch (int.tryParse(text)) {
          _ when text.isEmpty || text == "-" => null,
          final level? when level.abs() <= maxMagnitude =>
            level > ownLevel ? "Can't be above your own power level" : null,
          // Including ones too far from zero to even parse
          _ => "Must be from -$maxMagnitude to $maxMagnitude",
        },
      ),
    );
  }
}
