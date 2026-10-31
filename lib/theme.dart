import 'package:flutter/material.dart';

class Brand {
  static const red = Color(0xFFD2213A);
  static const redDark = Color(0xFFA4152A);
  static const ink = Color(0xFF15192B);
  static const inkSoft = Color(0xFF5A6075);
  static const page = Color(0xFFF4F5F8);
  static const line = Color(0xFFE3E6EE);
  static const ok = Color(0xFF0E8F5E);
  static const gold = Color(0xFFF2A413);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: Brand.page,
    colorScheme: base.colorScheme.copyWith(
      primary: Brand.red,
      secondary: Brand.redDark,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Brand.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Brand.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    textTheme: base.textTheme.apply(bodyColor: Brand.ink, displayColor: Brand.ink),
  );
}
