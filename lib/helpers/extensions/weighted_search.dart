import "package:collection/collection.dart";
import "package:fast_immutable_collections/fast_immutable_collections.dart";

extension WeightedSearch<T> on Iterable<T> {
  /// The items with a field matching [query], best match first.
  IList<T> search(
    String query,
    Iterable<(String?, int)> Function(T item) fieldsOf,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return toIList();

    int qualityOf(String text) {
      final haystack = text.toLowerCase();
      if (haystack == needle) return 4;
      if (haystack.startsWith(needle)) return 3;
      if (haystack
          .split(RegExp(r"[\s_\-:/.@#!]+"))
          .any((w) => w.startsWith(needle))) {
        return 2;
      }
      if (haystack.contains(needle)) return 1;
      return 0;
    }

    return .new(
      map(
            (item) => (
              item,
              fieldsOf(item)
                      .map(
                        (field) => switch (field) {
                          (final text?, final weight) =>
                            qualityOf(text) * weight,
                          (null, _) => 0,
                        },
                      )
                      .maxOrNull ??
                  0,
            ),
          )
          .where((scored) => scored.$2 > 0)
          .sortedBy((scored) => -scored.$2)
          .map((scored) => scored.$1),
    );
  }
}
