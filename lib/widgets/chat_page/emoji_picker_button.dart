import "package:emoji_text_field/emoji_text_field.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:nexus/controllers/emoji_controller.dart";

class EmojiPickerButton extends HookConsumerWidget {
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
  Widget build(_, WidgetRef ref) => IconButton(
    onPressed: () async {
      onPressed?.call();
      final controller = this.controller ?? TextEditingController();

      final emojis = await ref.watch(EmojiController.provider.future);
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => EmojiKeyboardView(
            config: EmojiViewConfig(
              showRecentTab: false,
              customCategories: emojis.$1.unlock,
              customKeywords: emojis.$2.unlock,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              height: 600,
            ),
            textController: controller
              ..addListener(() {
                Navigator.of(context).pop();
                onSelection?.call(controller.text);
              }),
          ),
        );
      }
    },
    icon: Icon(Icons.emoji_emotions),
  );
}
