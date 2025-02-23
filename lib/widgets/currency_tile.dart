import 'package:currency_converter/widgets/result_tile.dart';
import 'package:flutter/material.dart';

import '../models/currency_code.dart';

class CurrencyTile extends StatelessWidget {
  final CurrencyCode currency;
  final double amount;
  final double rate;
  final VoidCallback onTap;

  const CurrencyTile({
    super.key,
    required this.currency,
    this.amount = 0.0,
    this.rate = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text("${currency.code} (${rate.toStringAsFixed(5)})"),
      subtitle: Text(currency.name),
      trailing: ResultTile(
        result: (rate * amount).toStringAsFixed(2),
      ),
    );
  }
}
