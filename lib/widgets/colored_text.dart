import 'package:flutter/material.dart';

class ColoredText extends StatelessWidget {
  final String text;
  Color? color;
  final double fontSize;

  ColoredText(
      {super.key, required this.text, this.color, this.fontSize = 14.0});

  @override
  Widget build(BuildContext context) {
    color ??= Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: fontSize),
      ),
    );
  }
}
