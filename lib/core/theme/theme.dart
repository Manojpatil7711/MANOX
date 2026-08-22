import 'package:flutter/material.dart';

final Color _primary = const Color(0xFF1DB954);
final Color _background = const Color(0xFF0A0A0A);

ThemeData manoxTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primary,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _background,
    colorScheme: colorScheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
