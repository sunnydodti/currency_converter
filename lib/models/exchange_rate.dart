class ExchangeRate {
  final String code;
  final double rate;

  ExchangeRate({required this.code, required this.rate});

  factory ExchangeRate.fromJson(Map<dynamic, dynamic> json) {
    return ExchangeRate(
      code: json['code'],
      rate: double.parse(json['rate'].toString()),
    );
  }
}