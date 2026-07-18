import "package:flutter/material.dart";

class Setting {
  final String title;
  final String description;
  final IconData icon;
  final Widget Function(String title, String description, IconData icon)
  builder;

  Setting({
    required this.title,
    required this.description,
    required this.builder,
    required this.icon,
  });
}
