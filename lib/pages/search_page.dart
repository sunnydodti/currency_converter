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

  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    searchController.dispose();
    resultController.dispose();
    _focusNode.dispose();
    super.dispose();
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
            rate: rate,
            onTap: () {
              _focusNode.unfocus();
              showCurrencyBottomSheet(context, _currencies[index], rate);
            },
          );
        },
      ),
    );
  }

  Future<dynamic> showCurrencyBottomSheet(
      BuildContext context, CurrencyCode currency, double rate) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(16),
            height: 230,
            child: Column(
              children: [
                ListTile(
                  title: Text(currency.name),
                  subtitle: Text("Rate: $rate"),
                  trailing: Text(currency.code.toUpperCase()),
                ),
                ListTile(
                  title: Text(
                      "$amount ${selected.code.toUpperCase()} is equivalent to:"),
                  subtitle:
                      Text("${currency.code.toUpperCase()}: ${rate * amount}"),
                ),
                Row(
                  children: [
                    _selectSearchButton(currency),
                    _selectResultButton(currency),
                  ],
                )
              ],
            ),
          );
        });
  }

  Expanded _selectResultButton(CurrencyCode currency) {
    return Expanded(
        child: ElevatedButton(
            onPressed: () async {
              _onResultChange(currency);
              await Future.delayed(Duration(milliseconds: 200));
              _focusNode.requestFocus();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text("Select Result")));
  }

  Expanded _selectSearchButton(CurrencyCode currency) {
    return Expanded(
        child: ElevatedButton(
            onPressed: () {
              _onSelectedChange(currency);
              if (mounted) Navigator.pop(context);
            },
            child: Text("Select Search")));
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
              focusNode: _focusNode,
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
            onChanged: _onResultChange,
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

  void _onResultChange(CurrencyCode? value) {
    setState(() {
      target = value!;
      resultController.text = _resultAmount() ?? "";
    });
    box.put(Constants.target, target.toJson());
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
    searchController.text = amount.toString();
    exchangeRates = FileDb.exchangeRates;
    resultController.text = _resultAmount() ?? "";

    setState(() {});
  }

  void _search() async {
    Map<dynamic, dynamic> result =
        await ApiService.getExchangeRate(selected.code);
    if (result.isEmpty) return;

    setState(() {
      exchangeRates = result;
      resultController.text = _resultAmount() ?? "";
    });

    box.put(Constants.exchangeRates, exchangeRates);
  }

  void _onAmountChange(String value) {
    if (value.isEmpty) {
      setState(() => amount = 0.0);
      resultController.text = _resultAmount() ?? "";
      return;
    }
    setState(() {
      amount = double.parse(value);
    });
    box.put(Constants.amount, amount);
  }

  void _onSelectedChange(CurrencyCode? value) {
    if (value == null) return;
    if (selected.code == value.code) return;

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    setState(() {
      selected = value;
    });

    _debounce = Timer(Duration(milliseconds: 200), () {
      _search();
      box.put(Constants.selected, selected.toJson());
      _debounce?.cancel();
    });
  }
}