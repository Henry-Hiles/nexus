import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:material_ui/material_ui.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/helpers/mxc_image.dart";
import "package:nexus/widgets/expandable_image.dart";
import "package:nexus/widgets/html/mention_chip.dart";
import "package:nexus/widgets/html/spoiler_text.dart";
import "package:nexus/widgets/html/code_block.dart";
import "package:nexus/widgets/html/quoted.dart";

class const Html(
  final String html, {
  final String? roomId,
  final TextStyle? textStyle,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => HtmlWidget(
    html,
    buildAsync: false,
    textStyle: textStyle,
    customWidgetBuilder: (element) {
      if (element.attributes.keys.contains("data-mx-profile-fallback")) {
        return SizedBox.shrink();
      }

      if (element.attributes.keys.contains("data-mx-spoiler")) {
        return InlineCustomWidget(child: SpoilerText(element.text));
      }

      final height =
          int.tryParse(element.attributes["height"] ?? "") ??
          (element.attributes.keys.contains("data-mx-emoticon") ? 32 : null) ??
          300;
      final width = int.tryParse(element.attributes["width"] ?? "");
      final src = Uri.tryParse(element.attributes["src"] ?? "");

      return switch (element.localName) {
        "code" =>
          element.parent?.localName == "pre"
              ? CodeBlock(
                  element.text,
                  lang: element.className.replaceAll("language-", ""),
                )
              : null,

        "blockquote" => Quoted(
          Html(element.innerHtml, textStyle: textStyle, roomId: roomId),
        ),

        "a" =>
          element.attributes["href"]?.mention == null
              ? null
              : InlineCustomWidget(
                  child: MentionChip(element.attributes["href"]!, roomId),
                ),

        "img" =>
          src == null
              ? SizedBox.shrink()
              : InlineCustomWidget(
                  alignment: PlaceholderAlignment.middle,
                  child: ExpandableImage(
                    .new(mxc: src),
                    child: Image(
                      image: MxcImage(ref, .new(mxc: src)),
                      errorBuilder: (_, error, _) => Text(
                        "Image Failed to Load",
                        style: .new(color: Theme.of(context).colorScheme.error),
                      ),
                      height: height.toDouble(),
                      width: width?.toDouble(),
                      loadingBuilder: (_, child, loadingProgress) =>
                          loadingProgress == null
                          ? child
                          : CircularProgressIndicator(),
                    ),
                  ),
                ),

        // Allowed elements list
        ("del" ||
            "h1" ||
            "h2" ||
            "h3" ||
            "h4" ||
            "h5" ||
            "h6" ||
            "p" ||
            "ul" ||
            "ol" ||
            "sup" ||
            "sub" ||
            "li" ||
            "b" ||
            "i" ||
            "u" ||
            "strong" ||
            "em" ||
            "s" ||
            "code" ||
            "hr" ||
            "br" ||
            "div" ||
            "table" ||
            "thead" ||
            "tbody" ||
            "tr" ||
            "th" ||
            "td" ||
            "caption" ||
            "pre" ||
            "span" ||
            "details" ||
            "summary") =>
          null,

        _ => SizedBox.shrink(),
      };
    },
    customStylesBuilder: (element) => {
      "width": "auto",
      ...Map.fromEntries(
        element.attributes
            .mapTo<MapEntry<String, String>?>(
              (key, value) => switch (key) {
                "data-mx-color" => .new("color", value),
                "data-mx-bg-color" => .new("background-color", value),
                _ => null,
              },
            )
            .nonNulls,
      ),
    },
    onTapUrl: (url) => ref.watch(LaunchHelper.provider).launchUrl(.parse(url)),
  );
}
