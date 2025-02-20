import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import '../data/constants.dart';

class ApiService {
  static final Box _box = Hive.box(Constants.box);
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

  static Future<Map<dynamic, dynamic>> getExchangeRate(String code) async {
    Map<dynamic, dynamic> exchangeRate = {};

    try {
      DateTime now = DateTime.now().subtract(Duration(hours: 5));
      String date = now.toUtc().toIso8601String().substring(0, 10);

      Map<dynamic, dynamic>? cache = _getExchangeRateFromCache(code, date);
      if (cache != null && cache.isNotEmpty) return cache;

      String url = _exchangeRateUrl.replaceFirst('__code__', code);
      url = url.replaceFirst('__date__', date);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return exchangeRate;
      Map<String, dynamic> data = json.decode(response.body);
      if (!data.containsKey(code) || data[code].isEmpty) {
        return exchangeRate;
      }
      exchangeRate = data[code];
      _saveExchangeRateToCache(code, date, exchangeRate);
      // for (var key in data[code].keys) {
      //   exchangeRate.add({"code": key, "rate": data[code][key]});
      // }
    } catch (e) {
      print(e);
    }
    return exchangeRate;
  }

  static _getExchangeRateFromCache(String code, String date) {
    return _box.get("cache_${date}_$code", defaultValue: {});
  }

  static _saveExchangeRateToCache(
      String code, String date, Map<dynamic, dynamic> data) {
    _box.put("cache_${date}_$code", data);
  }
}
