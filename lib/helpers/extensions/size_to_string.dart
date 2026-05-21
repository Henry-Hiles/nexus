import "package:fast_immutable_collections/fast_immutable_collections.dart";

extension SizeToString on int {
  String get sizeAsString {
    const IListConst<String> suffixes = IListConst([
      "B",
      "KB",
      "MB",
      "GB",
      "TB",
      "PB",
    ]);

    var i = 0;
    var size = toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
