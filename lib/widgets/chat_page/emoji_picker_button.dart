import "package:emoji_text_field/emoji_text_field.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

class EmojiPickerButton extends HookWidget {
  final TextEditingController? controller;
  final void Function(String emoji)? onSelection;
  final VoidCallback? onPressed;
  final BuildContext context;
  const EmojiPickerButton({
    this.controller,
    this.onPressed,
    this.onSelection,
    required this.context,
    super.key,
  });

  @override
  Widget build(_) => IconButton(
    onPressed: () {
      onPressed?.call();
      final controller = this.controller ?? TextEditingController();
      showBottomSheet(
        context: context,
        builder: (context) => EmojiKeyboardView(
          config: EmojiViewConfig(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            height: 600,
          ),
          textController: controller
            ..addListener(() async {
              Navigator.of(context).pop();
              onSelection?.call(controller.text);
            }),
        ),
      );
    },
    icon: Icon(Icons.emoji_emotions),
  );
}
