import "package:flutter/material.dart";

class Setting<T> {
  final String id;
  final String title;
  final T initialValue;
  final String description;
  final Widget Function(
    String title,
    String description,
    ValueChanged<T> onChanged,
    T currentValue,
  )
  builder;

  Setting({
    required this.id,
    required this.title,
    required this.initialValue,
    required this.description,
    required this.builder,
  });
}
