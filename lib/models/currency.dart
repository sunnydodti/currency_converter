class Currency {
  final String name;
  final String code;
  final double rate;
  final double base;
  String symbol;

  Currency(
      {required this.name,
      required this.code,
      this.base = 0.0,
      this.symbol = "",
      this.rate = 0.0});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      name: json['name'],
      code: json['code'],
      symbol: json['symbol'],
    );
  }

  String get rateString => rate.toStringAsFixed(2);

  String getRate(double multiplier) {
    return (rate * multiplier).toStringAsFixed(2);
  }

  String getRateFor(Currency currency, double multiplier) {
    // return (rate * multiplier * currency.rate).toStringAsFixed(2);
    double result = rate * multiplier * currency.rate;
    return result.toStringAsFixed(2);
  }
}
