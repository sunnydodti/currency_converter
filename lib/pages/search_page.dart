import 'dart:async';

import 'package:currency_converter/data/file_db.dart';
import 'package:currency_converter/widgets/currency_tile.dart';
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
  Map<dynamic, dynamic> exchangeRates = {};

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
            _buildSearch(),
            _buildResults(),
            Divider(),
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
          double rate = 0.0;
          if (exchangeRates.isNotEmpty) {
            rate =
                double.parse(exchangeRates[_currencies[index].code].toString());
          }

          return CurrencyTile(
            currency: _currencies[index],
            amount: amount,
            rate: rate ?? 0.0,
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
            onChanged: _onSelectedChange,
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
              onChanged: _onAmountChange,
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
                resultController.text = _resultAmount() ?? "";
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
    if (!exchangeRates.containsKey(target.code)) return "0.0";
    double rate = exchangeRates[target.code];

    if (rate == 0 || rate == 0.0) return "0.0";
    double result = amount * rate;
    return result.toStringAsFixed(5);
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
    Map<dynamic, dynamic> result =
        await ApiService.getExchangeRate(selected.code);
    if (result.isEmpty) return;

    // exchangeRates = List<ExchangeRate>.from(result.map((x) {
    //   return ExchangeRate.fromJson(x);
    // }));

    setState(() {
      exchangeRates = result;
      resultController.text = _resultAmount() ?? "";
    });
  }

  void _onAmountChange(String value) {
    if (value.isEmpty) {
      setState(() => amount = 0.0);
      return;
    }
    String result = _resultAmount() ?? "";
    setState(() {
      amount = double.parse(value);
      if (result.isNotEmpty) resultController.text = result;
    });
    return;
  }

  void _onSelectedChange(CurrencyCode? value) {
    if (value == null) return;
    if (selected.code == value.code) return;

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    setState(() {
      selected = value;
    });

    _debounce = Timer(Duration(milliseconds: 1000), () {
      _search();
      _debounce.cancel();
    });
  }
}