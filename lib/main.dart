import 'package:currency_converter/data/theme.dart';
import 'package:currency_converter/pages/search_page.dart';
import 'package:flutter/material.dart';

import 'service/startup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartupService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const SearchPage(),
    );
  }
}