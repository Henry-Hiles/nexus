import "package:material_ui/material_ui.dart";
import "package:flutter_linkify/flutter_linkify.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/helpers/launch_helper.dart";

final class const LinkifiedText(
  final String text, {
  final int? maxLines,
  final TextStyle? style,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Linkify(
    text: text,
    maxLines: maxLines,
    style: style,
    options: .new(humanize: false),
    onOpen: (link) =>
        ref.watch(LaunchHelper.provider).launchUrl(.parse(link.url)),
    linkStyle: .new(color: Theme.of(context).colorScheme.primary),
    overflow: maxLines == null ? null : .ellipsis,
  );
}
