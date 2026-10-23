import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/helpers/hooks/saving.dart";

/// Centered text that's edited in place, saving when submitted or unfocused.
class const InlineTextField({
  required final String? value,
  required final String hint,

  /// Disables the field if null, and while a returned future runs.
  required final FutureOr<void> Function(String value)? onChanged,
  final TextStyle? style,

  /// Pads the start to match the edit icon, keeping the text centered when the
  /// field is on its own, rather than beside others.
  final bool balanced = true,
  super.key,
}) extends HookWidget {
  static double iconSizeOf(TextStyle? style) =>
      ((style?.fontSize ?? 16) * 0.7).clamp(16.0, 24.0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final saving = Saving.use();
    final controller = useTextEditingController(text: value);
    final isEmpty = useValueListenable(controller).text.isEmpty;
    final focusNode = useFocusNode();
    final focused = useListenableSelector(focusNode, () => focusNode.hasFocus);
    final latest = useRef(value);
    latest.value = value;

    // Show changes made elsewhere, unless they'd overwrite an edit. Effects run
    // while building, so this waits until after, to not rebuild the field mid-build.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && !focusNode.hasFocus) {
          controller.text = value ?? "";
        }
      });
      return null;
    }, [value]);

    useEffect(() {
      Future<void> listener() async {
        if (focusNode.hasFocus) return;
        final text = controller.text.trim();
        if (text != (latest.value ?? "")) {
          await saving.run(() => onChanged?.call(text));
        }

        if (context.mounted && !focusNode.hasFocus) {
          controller.text = latest.value ?? "";
        }
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode, onChanged]);

    const border = UnderlineInputBorder(borderRadius: .zero, borderSide: .none);
    final iconSize = iconSizeOf(style);
    final iconConstraints = BoxConstraints.tight(Size(iconSize + 12, iconSize));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(.escape): () {
          controller.text = value ?? "";
          focusNode.unfocus();
        },
      },
      // Sized to the text, so the edit icon sits beside it
      child: IntrinsicWidth(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: onChanged != null && !saving.active,
          style: style,
          textAlign: .center,
          textCapitalization: .sentences,
          // Wraps long text, but stays one line, with enter saving it
          maxLines: null,
          keyboardType: .text,
          textInputAction: .done,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          onSubmitted: (_) => focusNode.unfocus(),
          onTapOutside: (_) => focusNode.unfocus(),
          decoration: .new(
            // The hint counts towards the field's width, so it's only set when it shows
            hintText: isEmpty ? hint : null,
            hintStyle: style?.copyWith(color: colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Colors.transparent,
            hoverColor: colorScheme.surfaceContainerHighest,
            isDense: true,
            // Without the prefix, this keeps the text off the edge of the hover background
            contentPadding: EdgeInsetsDirectional.only(
              start: balanced ? 0 : 6,
              top: 8,
              bottom: 8,
            ),
            border: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            prefixIcon: balanced ? const SizedBox() : null,
            prefixIconConstraints: iconConstraints,
            suffixIcon: saving.active
                ? Center(
                    child: SizedBox.square(
                      dimension: iconSize - 4,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.edit,
                    size: iconSize,
                    color: focused
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                        : colorScheme.onSurfaceVariant,
                  ),
            suffixIconConstraints: iconConstraints,
          ),
        ),
      ),
    );
  }
}
