import 'dart:async';

import 'package:currency_converter/data/file_db.dart';
import 'package:currency_converter/widgets/currency_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:search_choices/search_choices.dart';

import '../data/constants.dart';
import '../data/theme_provider.dart';
import '../models/currency_code.dart';
import '../service/api_service.dart';
import '../widgets/colored_button.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Box box = Hive.box(Constants.box);

  List<CurrencyCode> _currencies = [];
  List<DropdownMenuEntry<CurrencyCode>> dropdownMenuEntries = [];
  List<DropdownMenuItem<CurrencyCode>> dropdownMenuItems = [];
  Map<dynamic, dynamic> exchangeRates = {};

  late CurrencyCode fromCurrency;
  late CurrencyCode toCurrency;
  double amount = 0.0;

  String currencyDate = "";
  TextEditingController fromController = TextEditingController();
  TextEditingController toController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  bool searchByCode = true;
  bool searchByName = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildFrom(),
            _buildTo(),
            Divider(),
            _buildCurrencyList(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    Icon icon = Theme.of(context).brightness == Brightness.light
        ? Icon(Icons.light_mode_outlined)
        : Icon(Icons.dark_mode_outlined);
    return AppBar(
      title: Text("Currency Exchange"),
      centerTitle: true,
      actions: [
        IconButton(
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
            icon: icon),
      ],
    );
  }

  Expanded _buildCurrencyList() {
    return Expanded(
      child: Column(
        children: [
          _buildSearchField(),
          _buildSearchCount(),
          _buildSearchFilters(),
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                double rate = 0.0;
                if (exchangeRates.isNotEmpty) {
                  rate = double.parse(
                      exchangeRates[_currencies[index].code].toString());
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
          ),
        ],
      ),
    );
  }

  Padding _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        autofillHints: _currencies.map((e) => e.code).toList(),
        controller: searchController,
        decoration: InputDecoration(
          suffix: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              searchController.clear();
              _currencies = FileDb.currenciesList;
              setState(() {});
            },
          ),
          labelText: 'Search',
        ),
        onChanged: _onSearchChange,
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
                      "$amount ${fromCurrency.code.toUpperCase()} is equivalent to:"),
                  subtitle:
                      Text("${currency.code.toUpperCase()}: ${rate * amount}"),
                ),
                Row(
                  children: [
                    _selectFromButton(currency),
                    _selectToButton(currency),
                  ],
                )
              ],
            ),
          );
        });
  }

  Expanded _selectToButton(CurrencyCode currency) {
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
            child: Text(
              "To ${currency.code.toUpperCase()}",
              overflow: TextOverflow.fade,
            )));
  }

  Expanded _selectFromButton(CurrencyCode currency) {
    return Expanded(
        child: ElevatedButton(
            onPressed: () {
              _onFromChange(currency);
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              "From ${currency.code.toUpperCase()}",
              overflow: TextOverflow.fade,
            )));
  }

  Widget _buildFrom() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SearchChoices.single(
              items: dropdownMenuItems,
              value: fromCurrency,
              hint: "From",
              searchHint: "Search by currency name or code",
              onChanged: _onFromChange,
              isExpanded: true,
              displayClearIcon: false,
              searchFn: _dropDownSearch,
              selectedValueWidgetFn: (currency) {
                return Container(
                  padding: EdgeInsets.all(8),
                  child: Text(currency.code.toUpperCase()),
                );
              },
              closeButton: "Close",
            ),
          ),
          // onChanged: _onSelectedChange, value: _currencies[0]),
          Spacer(flex: 1),
          Expanded(
            flex: 3,
            child: TextField(
              textAlign: TextAlign.end,
              focusNode: _focusNode,
              controller: fromController,
              decoration: InputDecoration(
                hintText: "0.0",
                helperStyle: TextStyle(overflow: TextOverflow.fade),
                helper: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(fromCurrency.name)],
                ),
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

  _dropDownSearch(String keyword, items) {
    List<int> result = [];
    if (keyword.isEmpty) {
      result = Iterable<int>.generate(items.length).toList();
      return (result);
    }
    for (var i = 0; i < items.length; i++) {
      if (items[i].value.name.toLowerCase().contains(keyword.toLowerCase()) ||
          items[i].value.code.toLowerCase().contains(keyword.toLowerCase())) {
        result.add(i);
      }
    }
    return (result);
  }

  Widget _buildTo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SearchChoices.single(
              items: dropdownMenuItems,
              value: toCurrency,
              hint: "From",
              searchHint: "Search by currency name or code",
              onChanged: _onResultChange,
              isExpanded: true,
              displayClearIcon: false,
              searchFn: _dropDownSearch,
              selectedValueWidgetFn: (currency) {
                return Container(
                  padding: EdgeInsets.all(8),
                  child: Text(currency.code.toUpperCase()),
                );
              },
              closeButton: "Close",
            ),
          ),
          Spacer(flex: 1),
          Expanded(
            flex: 3,
            child: TextField(
              textAlign: TextAlign.end,
              enabled: false,
              controller: toController,
              decoration: InputDecoration(
                hintText: "0.0",
                helper: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(toCurrency.name)],
                ),
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
      toCurrency = value!;
      toController.text = _resultAmount() ?? "";
    });
    box.put(Constants.target, toCurrency.toJson());
  }

  String? _resultAmount() {
    if (exchangeRates.isEmpty) return null;
    if (!exchangeRates.containsKey(toCurrency.code)) return "0.0";
    double rate = double.parse(exchangeRates[toCurrency.code].toString());

    if (rate == 0 || rate == 0.0) return "0.0";
    double result = amount * rate;
    return result.toStringAsFixed(5);
  }

  void _initializeDefaults() {
    _currencies = FileDb.currenciesList;

    fromCurrency = FileDb.selected;
    toCurrency = FileDb.target;

    _currencies.removeWhere((e) => e.code == fromCurrency.code);
    _currencies.removeWhere((e) => e.code == toCurrency.code);
    _currencies.add(fromCurrency);
    _currencies.add(toCurrency);

    amount = FileDb.amount;
    fromController.text = amount.toString();
    exchangeRates = FileDb.exchangeRates;
    toController.text = _resultAmount() ?? "";

    dropdownMenuEntries = _currencies.map(
      (currency) {
        return DropdownMenuEntry(
          value: currency,
          label: currency.code,
        );
      },
    ).toList();

    dropdownMenuItems = _currencies.map(
      (currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(currency.code),
        );
      },
    ).toList();

    setState(() {});
  }

  void _search() async {
    Map<dynamic, dynamic> result =
        await ApiService.getExchangeRate(fromCurrency.code);
    if (result.isEmpty) return;

    setState(() {
      exchangeRates = result;
      toController.text = _resultAmount() ?? "";
    });

    box.put(Constants.exchangeRates, exchangeRates);
  }

  void _onAmountChange(String value) {
    if (value.isEmpty) {
      setState(() => amount = 0.0);
      toController.text = _resultAmount() ?? "";
      return;
    }
    setState(() {
      amount = double.parse(value);
      toController.text = _resultAmount() ?? "";
    });
    box.put(Constants.amount, amount);
  }

  void _onFromChange(CurrencyCode? value) {
    if (value == null) return;
    if (fromCurrency.code == value.code) return;

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    setState(() {
      fromCurrency = value;
    });

    _debounce = Timer(Duration(milliseconds: 200), () {
      _search();
      box.put(Constants.selected, fromCurrency.toJson());
      _debounce?.cancel();
    });
  }

  _onSearchChange(String value) {
    if (value.isEmpty) {
      _currencies = FileDb.currenciesList;
      setState(() {});
      return;
    }

    _currencies = FileDb.currenciesList.where((element) {
      if (searchByName &&
          element.name.toLowerCase().contains(value.toLowerCase())) {
        return true;
      }
      if (searchByCode && element.code.contains(value.toLowerCase())) {
        return true;
      }
      return false;
    }).toList();
    setState(() {});
  }

  Widget _buildSearchCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            "Showing ${_currencies.length} of ${FileDb.currenciesList.length}",
            textScaler: TextScaler.linear(.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    if (searchController.text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Row(
        children: [
          Text("Search by:"),
          SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ColoredButton(
                    text: "Currency Name",
                    onPressed: () {
                      searchByName = !searchByName;
                      _onSearchChange(searchController.text);
                    },
                    isActive: searchByName,
                  ),
                  SizedBox(width: 8),
                  ColoredButton(
                    text: "Currency Code",
                    onPressed: () {
                      searchByCode = !searchByCode;
                      _onSearchChange(searchController.text);
                    },
                    isActive: searchByCode,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}