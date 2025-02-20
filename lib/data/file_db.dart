import '../models/currency_code.dart';

class FileDb {
  static List<CurrencyCode> currenciesList = [];
  static Map<dynamic, dynamic> exchangeRates = {};

  static CurrencyCode selected = CurrencyCode(name: "Euro", code: "eur");
  static CurrencyCode target = CurrencyCode(name: "Indian Rupee", code: "inr");

  static double amount = 0.0;
}