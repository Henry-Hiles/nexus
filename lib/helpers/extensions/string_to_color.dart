import "package:color_hash/color_hash.dart";
import "package:flutter/material.dart";

extension ToColor on String {
  Color get colorHash => ColorHash(this, lightness: .5, saturation: .7).color;
}
