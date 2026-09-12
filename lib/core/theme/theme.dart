import 'package:flutter/material.dart';

const _ink = Color(0xFF070709);
const _surface = Color(0xFF111116);
const _surfaceHigh = Color(0xFF1A1A21);
const _surfaceBright = Color(0xFF22222B);
const _line = Color(0xFF2A2A34);
const _muted = Color(0xFF9B9BA8);
const _accent = Color(0xFF8B5CF6);
const _accentSoft = Color(0xFFB8A1FF);
const _cyan = Color(0xFF67E8F9);

ThemeData manoxTheme() {
  final colorScheme = const ColorScheme.dark(
    primary: _accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF35205F),
    onPrimaryContainer: Color(0xFFE9DEFF),
    secondary: _cyan,
    onSecondary: _ink,
    secondaryContainer: Color(0xFF12383D),
    onSecondaryContainer: Color(0xFFD5FAFF),
    surface: _surface,
    onSurface: Colors.white,
    surfaceContainerHighest: _surfaceHigh,
    onSurfaceVariant: _muted,
    outline: _line,
    outlineVariant: Color(0xFF202027),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _ink,
    colorScheme: colorScheme,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _line),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _ink,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      hintStyle: const TextStyle(color: _muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _surfaceBright,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: _line),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _accentSoft,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: _surface,
      indicatorColor: Color(0xFF30204F),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: _surface,
      indicatorColor: Color(0xFF30204F),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _surfaceHigh,
      selectedColor: const Color(0xFF30204F),
      side: const BorderSide(color: _line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
    dividerTheme: const DividerThemeData(color: _line, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _accent,
      linearTrackColor: _line,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
      headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.45),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.15),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, color: _muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .2),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
