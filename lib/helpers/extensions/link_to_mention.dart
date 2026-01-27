extension LinkToMention on String {
  /// Extracts a Matrix identifier from this string.
  ///
  /// Supports:
  /// - https://matrix.to/#/...
  /// - matrix:roomid/...
  /// - matrix:r/...
  /// - matrix:u/...
  ///
  /// Returns the decoded identifier (e.g. "#room:matrix.org")
  /// or null if this is not a Matrix link.
  String? get mention {
    final trimmed = trim();

    final matrixTo = RegExp(
      r"^https?://matrix\.to/#/([^/?#]+)",
      caseSensitive: false,
    );

    final matrixToMatch = matrixTo.firstMatch(trimmed);
    if (matrixToMatch != null) {
      return Uri.decodeComponent(matrixToMatch.group(1)!);
    }

    if (trimmed.toLowerCase().startsWith("matrix:")) {
      try {
        final uri = Uri.parse(trimmed);

        if (uri.pathSegments.isNotEmpty) {
          final identifier = uri.pathSegments.last;
          if (identifier.isNotEmpty) {
            return Uri.decodeComponent(identifier);
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
