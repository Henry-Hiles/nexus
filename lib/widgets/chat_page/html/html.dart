import "package:cross_cache/cross_cache.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/cross_cache_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/extensions/link_to_mention.dart";
import "package:nexus/helpers/extensions/mxc_to_https.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/widgets/chat_page/expandable_image.dart";
import "package:nexus/widgets/chat_page/html/mention_chip.dart";
import "package:nexus/widgets/chat_page/html/spoiler_text.dart";
import "package:nexus/widgets/chat_page/html/code_block.dart";
import "package:nexus/widgets/chat_page/html/quoted.dart";

class Html extends ConsumerWidget {
  final String html;
  final TextStyle? textStyle;
  const Html(this.html, {this.textStyle, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HtmlWidget(
    html,
    textStyle: textStyle,
    customWidgetBuilder: (element) {
      if (element.attributes.keys.contains("data-mx-profile-fallback")) {
        return SizedBox.shrink();
      }

      if (element.attributes.keys.contains("data-mx-spoiler")) {
        return InlineCustomWidget(child: SpoilerText(text: element.text));
      }

      final height = int.tryParse(element.attributes["height"] ?? "") ?? 300;
      final width = int.tryParse(element.attributes["width"] ?? "");
      final src = Uri.tryParse(element.attributes["src"] ?? "")
          ?.mxcToHttps(
            ref.watch(
                  ClientStateController.provider.select(
                    (value) => value?.homeserverUrl,
                  ),
                ) ??
                "",
          )
          .toString();

      return switch (element.localName) {
        "code" =>
          element.parent?.localName == "pre"
              ? CodeBlock(
                  element.text,
                  lang: element.className.replaceAll("language-", ""),
                )
              : null,

        "blockquote" => Quoted(Html(element.innerHtml)),

        "a" =>
          element.attributes["href"]?.mention == null
              ? null
              : InlineCustomWidget(child: MentionChip(element.text)),

        "img" =>
          src == null
              ? SizedBox.shrink()
              : InlineCustomWidget(
                  alignment: PlaceholderAlignment.middle,
                  child: ExpandableImage(
                    src,
                    child: Image(
                      image: CachedNetworkImage(
                        src,
                        ref.watch(CrossCacheController.provider),
                        headers: ref.headers,
                      ),
                      errorBuilder: (_, error, _) => Text(
                        "Image Failed to Load",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                "data-mx-color" => MapEntry("color", value),
                "data-mx-bg-color" => MapEntry("background-color", value),
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
