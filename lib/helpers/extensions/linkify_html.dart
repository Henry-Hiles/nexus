import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:linkify/linkify.dart";
import "package:nexus/helpers/matrix_linkifier.dart";

extension LinkifyHtml on String {
  /// Wraps bare links in this HTML's text in `<a>` tags.
  ///
  /// Only text nodes are touched, so attribute values are left alone, and
  /// text already inside a link or code is skipped.
  String get linkifiedHtml {
    final fragment = parseFragment(this);
    _linkifyNode(fragment);
    return fragment.outerHtml;
  }
}

void _linkifyNode(Node node) {
  if (node is Element && const {"a", "code", "pre"}.contains(node.localName)) {
    return;
  }

  for (final child in node.nodes.toList()) {
    if (child is! Text) {
      _linkifyNode(child);
      continue;
    }

    final elements = linkifyText(child.data);
    if (!elements.any((element) => element is LinkableElement)) continue;

    elements
        .map(
          (element) => switch (element) {
            LinkableElement(:final text, :final url) =>
              Element.tag("a")
                ..attributes["href"] = url
                ..append(Text(text)),
            _ => Text(element.text),
          },
        )
        .forEach((replacement) => node.insertBefore(replacement, child));
    child.remove();
  }
}
