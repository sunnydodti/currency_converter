import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static final String _currencyListUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json';
  static final String _exchangeRateUrl =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@__date__/v1/currencies/__code__.json';

  static Future<List<Map<String, String>>> getCurrencyList() async {
    List<Map<String, String>> currencies = [];

    try {
      final response = await http.get(Uri.parse(_currencyListUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        data.forEach((key, value) {
          currencies.add({"name": value, "code": key});
        });
      }
    } catch (e) {
      print(e);
    }
    return currencies;
  }

  static Future<List<Map<dynamic, dynamic>>> getExchangeRate(String code) async {
    List<Map<dynamic, dynamic>> exchangeRate = [];

    try {
      String date = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      String url = _exchangeRateUrl.replaceFirst('__code__', code);
      url = url.replaceFirst('__date__', date);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return exchangeRate;
      Map<String, dynamic> data = json.decode(response.body);
      if (!data.containsKey(code) || data[code].isEmpty) {
        return exchangeRate;
      }
      // data[code].map((key, value) {
      //   exchangeRate.add({"name": key, "rate": value});
      // });
      for (var key in data[code].keys) {
        exchangeRate.add({"code": key, "rate": data[code][key]});
      }

    } catch (e) {
      print(e);
    }
    return exchangeRate;
  }
}
