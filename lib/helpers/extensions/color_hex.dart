import "package:flutter/widgets.dart";

extension ColorHex on Color {
  String get hex {
    final rgb = toARGB32() & 0x00FFFFFF;
    return "#${rgb.toRadixString(16).padLeft(6, "0")}";
  }
}
