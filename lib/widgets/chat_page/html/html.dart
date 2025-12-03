import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/widgets/chat_page/html/spoiler_text.dart";
import "package:nexus/widgets/chat_page/html/code_block.dart";
import "package:nexus/widgets/chat_page/quoted.dart";

class Html extends ConsumerWidget {
  final String html;
  const Html(this.html, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HtmlWidget(
    html,
    customWidgetBuilder: (element) {
      if (element.attributes.keys.contains("data-mx-spoiler")) {
        return SpoilerText(text: element.text);
      }
      return switch (element.localName) {
        "mx-reply" => SizedBox.shrink(),

        "code" => CodeBlock(
          element.text,
          lang: element.className.replaceAll("language-", ""),
        ),

        "blockquote" => Quoted(Html(element.innerHtml)),

        ("del" ||
            "h1" ||
            "h2" ||
            "h3" ||
            "h4" ||
            "h5" ||
            "h6" ||
            "p" ||
            "a" ||
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
            "img" ||
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
                "data-mx-color" => MapEntry("color", value),

                "data-mx-bg-color" => MapEntry("background-color", value),

                "edited" => MapEntry("display", "block"),

                _ => null,
              },
            )
            .nonNulls,
      ),
    },
    onTapUrl: (url) =>
        ref.watch(LaunchHelper.provider).launchUrl(Uri.parse(url)),
  );
}
