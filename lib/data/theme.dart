import 'package:flutter/material.dart';

MaterialColor accentColor = Colors.blue;

ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: accentColor,
    surface: Colors.grey.shade200,
  ),
  useMaterial3: true,
);

ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: accentColor,
    surface: Colors.grey.shade900,
  ),
  useMaterial3: true,
);
