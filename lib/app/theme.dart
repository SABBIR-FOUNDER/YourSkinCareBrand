import 'package:flutter/material.dart';

abstract final class Brand {
  static const rose = Color(0xffa34864),
      petal = Color(0xfffff7f8),
      blush = Color(0xfff5e4e8),
      cocoa = Color(0xff34272b),
      taupe = Color(0xffe6d8d3),
      paper = Color(0xfffffdfc),
      muted = Color(0xff68595e);
}

ThemeData shopTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Brand.rose).copyWith(
    primary: Brand.rose,
    onPrimary: Colors.white,
    surface: Brand.paper,
    onSurface: Brand.cocoa,
    onSurfaceVariant: Brand.muted,
    outlineVariant: Brand.taupe,
    secondaryContainer: Brand.blush,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Public Sans',
    colorScheme: scheme,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(11));
  const heading = TextStyle(
    fontFamily: 'Public Sans',
    color: Brand.cocoa,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Brand.paper,
    textTheme: base.textTheme.copyWith(
      headlineLarge: heading.copyWith(fontSize: 32, height: 1.14),
      headlineMedium: heading.copyWith(fontSize: 28),
      titleLarge: heading.copyWith(fontSize: 22),
      bodyLarge: const TextStyle(
        fontFamily: 'Public Sans',
        fontSize: 15,
        height: 1.45,
        color: Brand.cocoa,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Brand.taupe,
      space: 1,
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 48),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        shape: shape,
        side: const BorderSide(color: Brand.taupe),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Brand.taupe),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: Brand.blush,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Brand.taupe),
      shape: const StadiumBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Brand.cocoa,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
