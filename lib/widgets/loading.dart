import "package:flutter/material.dart";

class Loading extends StatelessWidget {
  final double? height;
  const Loading({this.height, super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(height: height, child: CircularProgressIndicator()),
    ),
  );
}
