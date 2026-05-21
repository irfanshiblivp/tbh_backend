import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color ink = Color(0xFF0C0C11);
  static const Color primary = ink;
  static const Color ink2 = Color(0xFF14141C);
  static const Color amber = Color(0xFFFF5C00); // Deep Dark Orange
  static const Color amber2 = Color(0xFFFF8C00); // Accent Orange
  static const Color cream = Color(0xFFF5F0E8);
  static const Color text = Color(0xFFF2EFE9);
  static const Color text2 = Color(0xFFA09C98);
  static const Color card = Color(0x0CFFFFFF);
  static const Color card2 = Color(0x14FFFFFF);
  static const Color line = Color(0x12FFFFFF);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF07070A),
    primaryColor: AppColors.amber,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.amber,
      onPrimary: Colors.white,
      secondary: AppColors.amber2,
      onSecondary: Colors.white,
      surface: AppColors.ink2,
      background: Color(0xFF07070A),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        color: AppColors.text,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.jost(
        color: AppColors.text,
      ),
      bodyMedium: GoogleFonts.jost(
        color: AppColors.text2,
      ),
      labelSmall: GoogleFonts.dmMono(
        color: AppColors.amber,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink2,
      contentTextStyle: GoogleFonts.jost(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
    ),
  );

  static IconData getCategoryIcon(String? name) {
    final t = (name ?? '').toLowerCase();
    if (t.contains('restaurant') || t.contains('food')) return Icons.restaurant;
    if (t.contains('hotel') || t.contains('resort')) return Icons.hotel;
    if (t.contains('fashion') || t.contains('clothing')) return Icons.checkroom;
    if (t.contains('jewellery') || t.contains('gold')) return Icons.diamond;
    if (t.contains('bar') || t.contains('cafe')) return Icons.local_bar;
    if (t.contains('electronics') || t.contains('mobile')) return Icons.devices;
    if (t.contains('spa') || t.contains('wellness') || t.contains('beauty')) return Icons.spa;
    if (t.contains('auto')) return Icons.directions_car;
    if (t.contains('book') || t.contains('stationery')) return Icons.menu_book;
    if (t.contains('travel')) return Icons.flight;
    if (t.contains('health') || t.contains('medical')) return Icons.medical_services;
    return Icons.storefront;
  }
}
