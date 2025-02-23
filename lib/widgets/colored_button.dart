import 'package:currency_converter/widgets/colored_text.dart';
import 'package:flutter/material.dart';

class ColoredButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isActive;
  final bool toggle;

  const ColoredButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isActive = false,
    this.toggle = true,
  });

  @override
  State<ColoredButton> createState() => _ColoredButtonState();
}

class _ColoredButtonState extends State<ColoredButton> {
  bool _isActive = false;
  bool toggle = true;

  @override
  void initState() {
    super.initState();
    _isActive = widget.isActive;
    toggle = widget.toggle;
  }

  @override
  Widget build(BuildContext context) {
    Color color = getColor();
    return GestureDetector(
      onTap: () {
        if (toggle) setState(() => _isActive = !_isActive);
        print("Button pressed");
        widget.onPressed();
      },
      child: ColoredText(text: widget.text, color: color),
    );
  }

  Color getColor() {
    if (_isActive) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.primary.withAlpha(50);
  }
}
