import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import '../data/constants.dart';

class ApiService {
  static final Box _box = Hive.box(Constants.box);

  static final String _currencyListUrlPrimary =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.min.json';
  static final String _exchangeRateUrlPrimary =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/__code__.min.json';

  static final String _currencyListUrlSecondary =
      'https://latest.currency-api.pages.dev/v1/currencies.min.json';
  static final String _exchangeRateUrlSecondary =
      'https://latest.currency-api.pages.dev/v1/currencies/__code__.min.json';

  static final Duration timeout = const Duration(seconds: 5);

  static Future<List<Map<String, String>>> getCurrencyList() async {
    List<Map<String, String>> currencies = [];

    try {
      http.Response response =
          await http.get(Uri.parse(_currencyListUrlPrimary)).timeout(timeout);
      if (response.statusCode != 200) {
        response = await http
            .get(Uri.parse(_currencyListUrlSecondary))
            .timeout(timeout);
        if (response.statusCode != 200) return currencies;
      }
      final Map<String, dynamic> data = json.decode(response.body);

      data.forEach((key, value) {
        currencies.add({"name": value, "code": key});
      });
    } catch (e) {
      print(e);
    }
    return currencies;
  }

  static Future<Map<dynamic, dynamic>> getExchangeRate(String code) async {
    Map<dynamic, dynamic> exchangeRate = {};

    try {
      DateTime now = DateTime.now().toUtc();
      String date = now.toIso8601String().substring(0, 10);

      Map<dynamic, dynamic>? cache = _getExchangeRateFromCache(code, date);
      if (cache != null && cache.isNotEmpty) return cache;

      String url = _exchangeRateUrlPrimary.replaceFirst('__code__', code);
      // url = url.replaceFirst('latest', date);

      http.Response response = await http.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode != 200) {
        response = await http
            .get(Uri.parse(_exchangeRateUrlSecondary))
            .timeout(timeout);
        if (response.statusCode != 200) return exchangeRate;
      }

      Map<String, dynamic> data = json.decode(response.body);
      // DateTime currencyDate = DateTime.parse(data['date']);

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
