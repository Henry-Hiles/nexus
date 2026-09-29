import "package:fast_immutable_collections/fast_immutable_collections.dart";

/// A parsed Matrix link.
///
/// [identifier] is the room ID, room alias or user ID (e.g. "#room:matrix.org"),
/// [eventId] is set for event permalinks (e.g. "$abc123"), and [via] holds any
/// `via` servers from the link.
typedef LinkInfo = ({String identifier, String? eventId, IList<String> via});

extension GetLinkInfo on String {
  /// Parses this string as a Matrix link.
  ///
  /// Supports:
  /// - https://matrix.to/#/{id}[/{eventId}][?via=...]
  /// - matrix:roomid/{id}[/e/{eventId}][?via=...]
  /// - matrix:r/{alias}[/e/{eventId}][?via=...]
  /// - matrix:u/{userId}
  ///
  /// Returns null if this is not a Matrix link.
  LinkInfo? get linkInfo {
    final uri = Uri.tryParse(trim());
    if (uri == null) return null;

    if ((uri.scheme == "http" || uri.scheme == "https") &&
        uri.host == "matrix.to") {
      // matrix.to keeps everything, including the query, in the fragment,
      // so parse the fragment as its own URI.
      final inner = Uri.tryParse(uri.fragment);
      final segments = inner?.pathSegments.where((s) => s.isNotEmpty).toList();
      if (inner == null || segments == null || segments.isEmpty) return null;

      return (
        identifier: segments.first,
        eventId: segments.length > 1 && segments[1].startsWith(r"$")
            ? segments[1]
            : null,
        via: .new(inner.queryParametersAll["via"] ?? []),
      );
    }

    if (uri.scheme == "matrix") {
      final segments = uri.pathSegments;
      if (segments.length < 2 || segments[1].isEmpty) return null;

      final sigil = switch (segments[0].toLowerCase()) {
        "r" => "#",
        "roomid" => "!",
        "u" => "@",
        _ => null,
      };
      if (sigil == null) return null;

      // Event segment is "e/{eventId}" (without the "$" sigil) and is
      // only valid on room links.
      final hasEvent =
          sigil != "@" &&
          segments.length >= 4 &&
          segments[2].toLowerCase() == "e" &&
          segments[3].isNotEmpty;

      return (
        identifier: "$sigil${segments[1]}",
        eventId: hasEvent ? "\$${segments[3]}" : null,
        via: .new(uri.queryParametersAll["via"] ?? []),
      );
    }

    return null;
  }
}
