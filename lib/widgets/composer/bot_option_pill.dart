import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:nexus/controllers/bot_command_draft.dart";
import "package:nexus/models/content/bot_command_description.dart";

class const BotOptionPill(
  final BotParameter parameter, {
  required final String roomId,

  /// Called on backspace while empty, to remove the parameter or command.
  final VoidCallback? onRemove,
  required final VoidCallback onSubmit,
  super.key,
}) extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = BotCommandDraftController.provider(roomId);
    final (:text, :isFocused, :error, :isLast) = ref.watch(
      provider.select(
        (draft) => (
          text: draft?.texts[parameter.key] ?? "",
          isFocused: draft?.focused == parameter.key,
          error: draft?.errors[parameter.key],
          isLast:
              draft?.missing.every((other) => other.key == parameter.key) ??
              true,
        ),
      ),
    );
    final controller = useTextEditingController(text: text);
    final focusNode = useFocusNode();

    useEffect(() {
      if (controller.text != text) {
        controller.value = .new(
          text: text,
          selection: .collapsed(offset: text.length),
        );
      }
      return null;
    }, [text]);

    useEffect(() {
      if (isFocused && !focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => focusNode.requestFocus(),
        );
      }
      return null;
    }, [isFocused]);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (focused) {
          ref.read(provider.notifier).focus(parameter.key);
        }
      },
      onKeyEvent: (_, event) {
        if (onRemove case final remove?
            when event is KeyDownEvent &&
                event.logicalKey == .backspace &&
                controller.text.isEmpty) {
          remove();
          return .handled;
        }
        return .ignored;
      },
      child: Container(
        padding: .symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isFocused ? colorScheme.primaryContainer : colorScheme.surface,
          border: error == null ? null : .all(color: colorScheme.error),
          borderRadius: .all(.circular(8)),
        ),
        child: Row(
          mainAxisSize: .min,
          spacing: 4,
          children: [
            Text(
              "${parameter.key}:",
              style: .new(
                fontWeight: .bold,
                color: isFocused
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: .new(minWidth: 16, maxWidth: 320),
                child: IntrinsicWidth(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: parameter.schema is LiteralSchema,
                    onChanged: (text) => ref
                        .read(provider.notifier)
                        .setText(parameter.key, text),
                    textInputAction: isLast ? .send : .next,
                    onSubmitted: (_) => onSubmit(),
                    // Keeps the keyboard open, rather than moving focus itself
                    onEditingComplete: () {},
                    keyboardType:
                        parameter.schema.allows(.integer) &&
                            !parameter.schema.allows(.string)
                        ? .number
                        : null,
                    decoration: .collapsed(hintText: null),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
