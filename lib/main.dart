import 'package:currency_converter/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/theme_provider.dart';
import 'service/startup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartupService.init();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: context.watch<ThemeProvider>().theme,
      home: const SearchPage(),
    );
  }
}