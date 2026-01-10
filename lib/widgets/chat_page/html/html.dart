import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:matrix/matrix.dart";
import "package:nexus/controllers/thumbnail_controller.dart";
import "package:nexus/helpers/extensions/get_headers.dart";
import "package:nexus/helpers/launch_helper.dart";
import "package:nexus/models/image_data.dart";
import "package:nexus/widgets/chat_page/html/mention_chip.dart";
import "package:nexus/widgets/chat_page/html/spoiler_text.dart";
import "package:nexus/widgets/chat_page/html/code_block.dart";
import "package:nexus/widgets/chat_page/html/quoted.dart";
import "package:nexus/widgets/error_dialog.dart";

class Html extends ConsumerWidget {
  final String html;
  final Client client;
  const Html(this.html, {required this.client, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => HtmlWidget(
    html,
    customWidgetBuilder: (element) {
      if (element.attributes.keys.contains("data-mx-spoiler")) {
        return InlineCustomWidget(child: SpoilerText(text: element.text));
      }

      final height = int.tryParse(element.attributes["height"] ?? "") ?? 300;
      final width = int.tryParse(element.attributes["width"] ?? "");

      return switch (element.localName) {
        "code" =>
          element.parent?.localName == "pre"
              ? CodeBlock(
                  element.text,
                  lang: element.className.replaceAll("language-", ""),
                )
              : null,

        "blockquote" => Quoted(Html(element.innerHtml, client: client)),

        "a" =>
          element.attributes["href"]?.parseIdentifierIntoParts() == null
              ? null
              : InlineCustomWidget(child: MentionChip(element.text)),

        "img" =>
          element.attributes["src"] == null
              ? null
              : Consumer(
                  builder: (_, ref, _) => ref
                      .watch(
                        ThumbnailController.provider(
                          ImageData(
                            uri: element.attributes["src"]!,
                            height: height,
                            width: width,
                          ),
                        ),
                      )
                      .when(
                        data: (uri) {
                          if (uri == null) return SizedBox.shrink();

                          return InlineCustomWidget(
                            child: Image.network(
                              uri,
                              headers: client.headers,
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
                          );
                        },
                        error: ErrorDialog.new,
                        loading: () => InlineCustomWidget(
                          child: SizedBox(
                            width: width?.toDouble(),
                            height: height.toDouble(),
                            child: CircularProgressIndicator(),
                          ),
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
