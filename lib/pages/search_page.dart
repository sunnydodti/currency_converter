import 'dart:async';

import 'package:currency_converter/data/file_db.dart';
import 'package:currency_converter/models/exchange_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

import '../data/constants.dart';
import '../models/currency_code.dart';
import '../service/api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Box box = Hive.box(Constants.box);

  List<CurrencyCode> _currencies = [];
  List<ExchangeRate> exchangeRates = [];

  late CurrencyCode selected;
  late CurrencyCode target;
  double amount = 0.0;

  String currencyDate = "";
  TextEditingController searchController = TextEditingController();
  TextEditingController resultController = TextEditingController();

  Timer _debounce = Timer(Duration(milliseconds: 1), () {});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeDefaults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Currency Exchange"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            GestureDetector(
              child: Text("refresh"),
              onTap: () {
                _initializeDefaults();
              },
            ),
            _buildSearch(),
            _buildResults(),
            Divider(),
            _buildCurrencies(),
            _buildCurrencyList(),
          ],
        ),
      ),
    );
  }

  Expanded _buildCurrencyList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _currencies.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_currencies[index].name),
            subtitle: Text(_currencies[index].code),
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          DropdownButton<CurrencyCode>(
            value: selected,
            items: _currencies.map((CurrencyCode currency) {
              return DropdownMenuItem<CurrencyCode>(
                value: currency,
                child: Text(currency.code),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selected = value!;
              });

              // trigger a debounced search
            },
          ),
          Spacer(),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "0.0",
                helperText: selected.name,
                helperStyle: TextStyle(overflow: TextOverflow.fade),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() => amount = 0.0);
                  return;
                }
                setState(() => amount = double.parse(value));

                // trigger a debounced search
                Timer(Duration(milliseconds: 1000), () {
                  _debounce.cancel();
                  _debounce = Timer(Duration(milliseconds: 1000), () {
                    _search();
                  });
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          DropdownButton<CurrencyCode>(
            value: target,
            items: _currencies.map((CurrencyCode currency) {
              return DropdownMenuItem<CurrencyCode>(
                value: currency,
                child: Text(currency.code),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                target = value!;
              });
            },
          ),
          Spacer(),
          Expanded(
            child: TextField(
              enabled: false,
              controller: resultController,
              decoration: InputDecoration(
                hintText: "0.0",
                helperText: target.name,
                helperStyle: TextStyle(overflow: TextOverflow.fade),
              ),
              readOnly: true,
            ),
          ),
          // ResultTile(result: _resultAmount()),
        ],
      ),
    );
  }

  String? _resultAmount() {
    if (exchangeRates.isEmpty) return null;

    ExchangeRate? rate = exchangeRates.firstWhere(
        (element) => element.code == target.code,
        orElse: () => ExchangeRate(code: "", rate: 0.0));
    if (rate.rate != 0.0) {
      double result = amount * rate.rate;
      return result.toStringAsFixed(2);
    }
    return "0.0";
  }

  Widget _buildCurrencies() {
    return SizedBox.shrink();
  }

  double _parseCurrency(dynamic value) {
    try {
      return double.parse(value.toString()).roundToDouble();
    } catch (e) {
      return 0.0;
    }
  }

  void _initializeDefaults() {
    _currencies = FileDb.currenciesList;

    selected = FileDb.selected;
    target = FileDb.target;

    _currencies.removeWhere((e) => e.code == selected.code);
    _currencies.removeWhere((e) => e.code == target.code);
    _currencies.add(selected);
    _currencies.add(target);

    amount = FileDb.amount;
    setState(() {});
  }

  void _search() async {
    List<Map<dynamic, dynamic>> result =
        await ApiService.getExchangeRate(selected.code);
    if (result.isEmpty) return;

    exchangeRates = List<ExchangeRate>.from(result.map((x) {
      return ExchangeRate.fromJson(x);
    }));

    setState(() {
      resultController.text = _resultAmount() ?? "";
    });
  }
}