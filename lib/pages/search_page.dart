import 'dart:async';

import 'package:currency_converter/data/file_db.dart';
import 'package:currency_converter/widgets/currency_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';

import '../data/constants.dart';
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
  Map<dynamic, dynamic> exchangeRates = {};

  late CurrencyCode selected;
  late CurrencyCode target;
  double amount = 0.0;

  String currencyDate = "";
  TextEditingController amountController = TextEditingController();
  TextEditingController resultController = TextEditingController();
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
    amountController.dispose();
    resultController.dispose();
    searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Icon icon = Theme.of(context).brightness == Brightness.light
        ? Icon(Icons.light_mode_outlined)
        : Icon(Icons.dark_mode_outlined);
    return Scaffold(
      appBar: AppBar(
        title: Text("Currency Exchange"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: icon),
        ],
      ),
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
            child: Text(
              "To ${currency.code.toUpperCase()}",
              overflow: TextOverflow.fade,
            )));
  }

  Expanded _selectSearchButton(CurrencyCode currency) {
    return Expanded(
        child: ElevatedButton(
            onPressed: () {
              _onSelectedChange(currency);
              if (mounted) Navigator.pop(context);
            },
            child: Text(
              "From ${currency.code.toUpperCase()}",
              overflow: TextOverflow.fade,
            )));
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownMenu<CurrencyCode>(
              helperText: 'From',
              enableSearch: true,
              enableFilter: true,
              selectedTrailingIcon: Icon(Icons.check_outlined),
              menuHeight: 300,
              initialSelection: selected,
              requestFocusOnTap: true,
              dropdownMenuEntries: dropdownMenuEntries,
              onSelected: _onSelectedChange,
            ),
          ),
          // onChanged: _onSelectedChange, value: _currencies[0]),
          Spacer(flex: 1),
          Expanded(
            flex: 3,
            child: TextField(
              textAlign: TextAlign.end,
              focusNode: _focusNode,
              controller: amountController,
              decoration: InputDecoration(
                hintText: "0.0",
                helperStyle: TextStyle(overflow: TextOverflow.fade),
                helper: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(selected.name)],
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

  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownMenu<CurrencyCode>(
              helperText: 'To',
              enableSearch: true,
              enableFilter: true,
              selectedTrailingIcon: Icon(Icons.check_outlined),
              menuHeight: 300,
              initialSelection: target,
              requestFocusOnTap: true,
              dropdownMenuEntries: dropdownMenuEntries,
              onSelected: _onResultChange,
            ),
          ),
          Spacer(flex: 1),
          Expanded(
            flex: 3,
            child: TextField(
              textAlign: TextAlign.end,
              enabled: false,
              controller: resultController,
              decoration: InputDecoration(
                hintText: "0.0",
                helper: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(target.name)],
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
      target = value!;
      resultController.text = _resultAmount() ?? "";
    });
    box.put(Constants.target, target.toJson());
  }

  String? _resultAmount() {
    if (exchangeRates.isEmpty) return null;
    if (!exchangeRates.containsKey(target.code)) return "0.0";
    double rate = double.parse(exchangeRates[target.code].toString());

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
    amountController.text = amount.toString();
    exchangeRates = FileDb.exchangeRates;
    resultController.text = _resultAmount() ?? "";

    dropdownMenuEntries = _currencies.map(
      (currency) {
        return DropdownMenuEntry(
          value: currency,
          label: currency.code,
        );
      },
    ).toList();

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
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ColoredButton(
                text: "Name",
                onPressed: () {
                  searchByName = !searchByName;
                  _onSearchChange(searchController.text);
                },
                isActive: searchByName,
              ),
              ColoredButton(
                  text: "Code",
                  onPressed: () {
                    searchByCode = !searchByCode;
                    _onSearchChange(searchController.text);
                  },
                  isActive: searchByCode),
            ],
          ))
        ],
      ),
    );
  }
}