import 'dart:convert';

import 'package:currency_converter/models/currency.dart';
import 'package:currency_converter/widgets/result_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/currency_tile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Currency> _currencies = [];
  List<double> exchangeRates = [];

  Currency? selectedCurrency;
  Currency? resultCurrency;
  double amount = 0.0;

  String currencyDate = "";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeCurrencies();
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
                _initializeCurrencies();
              },
            ),
            _buildSearch(),
            _buildResults(),
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
          return CurrencyTile(
            currency: _currencies[index],
            multiplier: amount,
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
          DropdownButton<Currency>(
            value: selectedCurrency,
            items: _currencies.map((Currency currency) {
              return DropdownMenuItem<Currency>(
                value: currency,
                child: Text(currency.code),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCurrency = value;
              });
            },
          ),
          Spacer(),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "0.0",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() => amount = 0.0);
                  return;
                }
                setState(() => amount = double.parse(value));
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
          DropdownButton<Currency>(
            value: resultCurrency,
            items: _currencies.map((Currency currency) {
              return DropdownMenuItem<Currency>(
                value: currency,
                child: Text(currency.code),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                resultCurrency = value;
              });
            },
          ),
          Spacer(),
          ResultTile(result: _resultAmount()),
        ],
      ),
    );
  }

  String? _resultAmount() {
    String? result = selectedCurrency?.getRateFor(resultCurrency!, amount);
    return result;
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

  void _initializeCurrencies() async {
    Map<String, String> currencies = await _getCurrencyList();
    Map<dynamic, dynamic> exchangeRates = await _getExchangeRates();
    List<Currency> currencyList = [];
    List<double> exchangeRateList = [];
    for (var key in currencies.keys) {
      currencyList.add(Currency(
          name: currencies[key]!,
          code: key.toUpperCase(),
          rate: _parseCurrency(exchangeRates[key])));
      exchangeRateList.add(0.0);
    }
    _currencies.clear();
    setState(() {
      _currencies = currencyList;
      // exchangeRates = exchangeRateList;
    });
  }

  Future<Map<String, String>> _getCurrencyList() async {
    Map<String, String> currencies = {};

    try {
      final response = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        data.forEach((key, value) {
          currencies[key] = value;
        });
      }
    } catch (e) {
      print(e);
    }
    return currencies;
  }

  Future<Map<dynamic, dynamic>> _getExchangeRates() async {
    Map<String, dynamic> exchangeRates = {};

    try {
      final response = await http.get(Uri.parse(
          'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/eur.json'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        exchangeRates = data['eur'];
      }
    } catch (e) {
      print(e);
    }
    return exchangeRates;
  }
}
