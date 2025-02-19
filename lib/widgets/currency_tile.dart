import 'package:currency_converter/models/currency.dart';
import 'package:flutter/material.dart';

class CurrencyTile extends StatelessWidget {
  final Currency currency;
  final double multiplier;
  const CurrencyTile({super.key, required this.currency, this.multiplier = 1.0});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("${currency.code} (${currency.rateString}"),
      subtitle: Text(currency.name),
      trailing: Text((currency.rate * multiplier).toStringAsFixed(2)),
    );
  }
}
