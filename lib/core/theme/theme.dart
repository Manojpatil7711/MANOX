import 'package:flutter/material.dart';

const _ink = Color(0xFF0B0B0C);
const _surface = Color(0xFF141416);
const _surfaceHigh = Color(0xFF1B1B1E);
const _line = Color(0xFF29292D);
const _muted = Color(0xFF9A9AA2);

ThemeData manoxTheme() {
  final colorScheme = const ColorScheme.dark(
    primary: Colors.white,
    onPrimary: _ink,
    secondary: Color(0xFFD8D8DC),
    onSecondary: _ink,
    surface: _surface,
    onSurface: Colors.white,
    surfaceContainerHighest: _surfaceHigh,
    onSurfaceVariant: _muted,
    outline: _line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _ink,
    colorScheme: colorScheme,
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _line),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _ink,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.2),
      ),
      hintStyle: const TextStyle(color: _muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: _line),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: _line, space: 1),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, color: _muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .2),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
