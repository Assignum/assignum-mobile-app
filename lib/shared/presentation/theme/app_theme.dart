import 'package:flutter/material.dart';

class AppColors {
  static const Color upcRed   = Color(0xFFE21221);
  static const Color upcBlack = Color(0xFF111111);
  static const Color upcGray  = Color(0xFF666666);
  static const Color upcLight = Color(0xFFF3F3F3);
  static const Color upcWhite = Colors.white;
}

final ThemeData upcTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.upcRed,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.upcLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.upcWhite,
    foregroundColor: AppColors.upcBlack,
    elevation: 0,
    centerTitle: true,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.upcWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.upcGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.upcRed, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.upcBlack),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.upcRed,
      foregroundColor: AppColors.upcWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
