import 'package:flutter/material.dart';

class AirCryptColors {
  AirCryptColors._();

  static const Color bgDark = Color(0xFF080C14);
  static const Color bgSurface = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF131C2E);
  static const Color cardBgElevated = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF1E293B);
  static const Color cyanGlow = Color(0xFF00F0FF);
  
  static const Color accentCyan = Color(0xFF00F0FF);
  static const Color accentBlue = Color(0xFF0072FF);
  static const Color accentGreen = Color(0xFF00FF87);
  static const Color accentAmber = Color(0xFFFFB300);
  static const Color accentRed = Color(0xFFFF2A6D);
  static const Color accentPurple = Color(0xFF8B5CF6);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static List<BoxShadow> cyberGlow({Color color = accentCyan, double opacity = 0.25}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 16,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: color.withOpacity(opacity * 0.5),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ];
  }
}

class AirCryptTheme {
  AirCryptTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AirCryptColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AirCryptColors.accentCyan,
        onPrimary: AirCryptColors.bgDark,
        secondary: AirCryptColors.accentBlue,
        onSecondary: AirCryptColors.textPrimary,
        surface: AirCryptColors.cardBg,
        onSurface: AirCryptColors.textPrimary,
        error: AirCryptColors.accentRed,
        onError: AirCryptColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AirCryptColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AirCryptColors.accentCyan),
        titleTextStyle: TextStyle(
          color: AirCryptColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AirCryptColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AirCryptColors.accentCyan.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AirCryptColors.accentCyan.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AirCryptColors.cardBgElevated,
        contentTextStyle: const TextStyle(color: AirCryptColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AirCryptColors.accentCyan.withOpacity(0.3)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AirCryptColors.bgSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AirCryptColors.accentCyan.withOpacity(0.3), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AirCryptColors.accentCyan,
          foregroundColor: AirCryptColors.bgDark,
          elevation: 4,
          shadowColor: AirCryptColors.accentCyan.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AirCryptColors.accentCyan,
          side: BorderSide(color: AirCryptColors.accentCyan.withOpacity(0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AirCryptColors.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AirCryptColors.accentCyan.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AirCryptColors.accentCyan.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AirCryptColors.accentCyan, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AirCryptColors.textSecondary),
        hintStyle: const TextStyle(color: AirCryptColors.textMuted),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AirCryptColors.accentCyan,
        textColor: AirCryptColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
