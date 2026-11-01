import "package:linkify/linkify.dart";

/// Splits [text] into plain text and URL, `matrix:` and email links.
List<LinkifyElement> linkifyText(String text) => linkify(
  text,
  options: const LinkifyOptions(humanize: false),
  linkifiers: const [UrlLinkifier(), MatrixLinkifier(), EmailLinkifier()],
);

/// Linkifies `matrix:` URIs, which [UrlLinkifier] only handles for http(s).
final class const MatrixLinkifier() extends Linkifier {
  static final _regex = RegExp(
    r"\bmatrix:[^\s<>\x22\x27]*[^\s<>\x22\x27.,;:!?)\]}]",
    caseSensitive: false,
  );

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) => elements
      .expand(
        (element) => element is TextElement ? _split(element.text) : [element],
      )
      .toList();

  Iterable<LinkifyElement> _split(String text) sync* {
    var start = 0;
    for (final match in _regex.allMatches(text)) {
      if (match.start > start) {
        yield TextElement(text.substring(start, match.start));
      }
      yield UrlElement(match[0]!);
      start = match.end;
    }
    if (start < text.length) yield TextElement(text.substring(start));
  }
}
