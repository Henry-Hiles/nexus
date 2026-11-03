import "package:flutter/gestures.dart";
import "package:material_ui/material_ui.dart";
import "package:linkify/linkify.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/extensions/get_link_info.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/helpers/matrix_linkifier.dart";
import "package:nexus/widgets/html/mention_chip.dart";

final class const LinkifiedText(
  final String text, {
  final String? roomId,
  final int? maxLines,
  final TextStyle? style,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Text.rich(
    TextSpan(
      style: style,
      children: linkifyText(text)
          .map<InlineSpan>(
            (element) => switch (element) {
              LinkableElement(:final url) when url.linkInfo != null =>
                WidgetSpan(
                  alignment: .baseline,
                  baseline: .alphabetic,
                  child: MentionChip(url, roomId),
                ),
              LinkableElement(:final text, :final url) => TextSpan(
                text: text,
                style: .new(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: .underline,
                ),
                mouseCursor: SystemMouseCursors.click,
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      ref.read(LaunchHelper.provider).launchUrl(.parse(url)),
              ),
              _ => TextSpan(text: element.text),
            },
          )
          .toList(),
    ),
    maxLines: maxLines,
    overflow: maxLines == null ? null : .ellipsis,
  );
}
