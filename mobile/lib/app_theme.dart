import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF10110F);
  static const surface = Color(0xFF191A17);
  static const surfaceRaised = Color(0xFF20211D);
  static const surfaceField = Color(0xFF141511);
  static const line = Color(0xFF30312B);
  static const text = Color(0xFFF0ECE2);
  static const muted = Color(0xFFA5A399);
  static const quiet = Color(0xFF77776F);
  static const gold = Color(0xFFC4A76D);
  static const goldBright = Color(0xFFE1C58B);
  static const green = Color(0xFF8EB59A);
  static const red = Color(0xFFD48678);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    primary: AppColors.goldBright,
    onPrimary: const Color(0xFF17150F),
    error: AppColors.red,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.line),
        borderRadius: BorderRadius.circular(5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceField,
      hintStyle: const TextStyle(color: AppColors.quiet, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppColors.red),
      ),
    ),
    dividerColor: AppColors.line,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.gold.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.goldBright : AppColors.quiet,
          )),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.goldBright),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFF17150F),
        backgroundColor: AppColors.goldBright,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.quiet,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );
}