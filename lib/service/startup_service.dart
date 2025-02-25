import 'package:currency_converter/data/file_db.dart';
import 'package:currency_converter/service/api_service.dart';
import 'package:hive_ce_flutter/adapters.dart';

import '../data/constants.dart';
import '../models/currency_code.dart';

class StartupService {
  static Future<void> init() async {
    await _init();

    // await getSharedPreferences();
    // await getCurrencyList();
    // await getExchangeRates();
  }

  static Future<void> _init() async {
    await _initHive();
    await _initDB();
  }

  static Future<void> _initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(Constants.box);
  }

  static Future<void> _initDB() async {
    Box box = Hive.box(Constants.box);

    final selected = box.get(Constants.selected);
    final target = box.get(Constants.target);
    final amount = box.get(Constants.amount);

    if (selected != null) FileDb.selected = CurrencyCode.fromJson(selected);
    if (target != null) FileDb.target = CurrencyCode.fromJson(target);
    if (amount != null) FileDb.amount = double.parse(amount.toString());

    List<dynamic>? currenciesList = box.get(Constants.currenciesList);
    currenciesList ??= await ApiService.getCurrencyList();

    if (currenciesList.isNotEmpty) {
      await box.put(Constants.currenciesList, currenciesList);
      FileDb.currenciesList = List<CurrencyCode>.from(
        currenciesList.map((x) {
          return CurrencyCode.fromJson(x);
        }));
    }

    Map<dynamic, dynamic>? exchangeRates = box.get(Constants.exchangeRates);
    exchangeRates ??= await ApiService.getExchangeRate(FileDb.selected.code);

    if (exchangeRates.isNotEmpty) {
      await box.put(Constants.exchangeRates, exchangeRates);
      FileDb.exchangeRates = exchangeRates;
    }
  }

  static Future<void> getCurrencyList() async {
    // Do some initial work here
  }

  static Future<void> getExchangeRates() async {
    // Do some initial work here
  }
}
