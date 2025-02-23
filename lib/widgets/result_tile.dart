import 'package:flutter/material.dart';

class ResultTile extends StatelessWidget {
  final String? result;
  final Color color;

  const ResultTile({super.key, required this.result, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        result!,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
