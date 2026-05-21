import "dart:math";

import "package:flutter/material.dart";

class CodeBlock extends StatelessWidget {
  final String code;
  final String lang;
  const CodeBlock(this.code, {required this.lang, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: IntrinsicWidth(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      lang.substring(0, min(lang.length, 15)),
                      style: TextStyle(fontFamily: "monospace"),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.copy),
                    label: Text("Copy"),
                  ),
                ],
              ),
              ColoredBox(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Container(
                  constraints: BoxConstraints(minWidth: 250),
                  padding: EdgeInsets.all(8),
                  child: SelectableText(
                    code,
                    minLines: 1,
                    maxLines: 99,
                    style: TextStyle(fontFamily: "monospace"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
