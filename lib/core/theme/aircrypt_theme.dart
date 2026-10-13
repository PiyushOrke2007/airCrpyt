import 'package:flutter/material.dart';

class AirCryptColors {
  AirCryptColors._();

  static const Color bgDark = Color(0xFFF9F9F7);
  static const Color bgSurface = Color(0xFFF9F9F7);
  static const Color cardBg = Color(0xFFF9F9F7);
  static const Color cardBgElevated = Color(0xFFF0F0ED);
  static const Color cardBorder = Color(0xFF1A1C1B);
  static const Color cyanGlow = Color(0xFF1A1C1B);

  static const Color accentCyan = Color(0xFF1A1C1B);
  static const Color accentBlue = Color(0xFF4F5754);
  static const Color accentGreen = Color(0xFF326747);
  static const Color accentAmber = Color(0xFF79551D);
  static const Color accentRed = Color(0xFF983B3B);
  static const Color accentPurple = Color(0xFF62577A);

  static const Color textPrimary = Color(0xFF1A1C1B);
  static const Color textSecondary = Color(0xFF4F5552);
  static const Color textMuted = Color(0xFF777C79);

  static List<BoxShadow> cyberGlow({
    Color color = accentCyan,
    double opacity = 0.25,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 16,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: color.withValues(alpha: opacity * 0.5),
        blurRadius: 4,
        spreadRadius: 0,
      ),
    ];
  }
}

class AirCryptTheme {
  AirCryptTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: AirCryptColors.bgDark,
      canvasColor: AirCryptColors.bgDark,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AirCryptColors.accentCyan,
        onPrimary: AirCryptColors.bgSurface,
        secondary: AirCryptColors.accentBlue,
        onSecondary: AirCryptColors.bgSurface,
        surface: AirCryptColors.cardBg,
        onSurface: AirCryptColors.textPrimary,
        error: AirCryptColors.accentRed,
        onError: AirCryptColors.bgSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AirCryptColors.bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        toolbarHeight: 60,
        iconTheme: IconThemeData(color: AirCryptColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AirCryptColors.textPrimary,
          fontFamily: 'Silkscreen',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
        actionsIconTheme: IconThemeData(color: AirCryptColors.textPrimary),
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Silkscreen',
        bodyColor: AirCryptColors.textPrimary,
        displayColor: AirCryptColors.textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Silkscreen'),
      cardTheme: CardThemeData(
        color: AirCryptColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AirCryptColors.cardBorder, width: 1.2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AirCryptColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AirCryptColors.cardBgElevated,
        contentTextStyle: const TextStyle(
          color: AirCryptColors.textPrimary,
          fontFamily: 'Silkscreen',
          fontSize: 10,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AirCryptColors.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AirCryptColors.bgSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AirCryptColors.cardBorder, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: AirCryptColors.accentCyan,
              foregroundColor: AirCryptColors.bgSurface,
              elevation: 4,
              shadowColor: AirCryptColors.accentCyan.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Silkscreen',
                letterSpacing: 0.2,
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.bgSurface;
                }
                return AirCryptColors.accentCyan;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.accentCyan;
                }
                return AirCryptColors.bgSurface;
              }),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)) {
                  return 0;
                }
                return 4;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: AirCryptColors.textPrimary,
              side: const BorderSide(
                color: AirCryptColors.cardBorder,
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Silkscreen',
                letterSpacing: 0.2,
              ),
              shadowColor: AirCryptColors.textPrimary.withValues(alpha: 0.22),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.textPrimary;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.bgSurface;
                }
                return AirCryptColors.textPrimary;
              }),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)) {
                  return 0;
                }
                return 3;
              }),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              foregroundColor: AirCryptColors.textPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              shadowColor: AirCryptColors.textPrimary.withValues(alpha: 0.18),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.textPrimary;
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AirCryptColors.bgSurface;
                }
                return AirCryptColors.textPrimary;
              }),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled) ||
                    states.contains(WidgetState.pressed)) {
                  return 0;
                }
                return 2;
              }),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AirCryptColors.textPrimary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AirCryptColors.bgSurface;
            }
            return AirCryptColors.textPrimary;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AirCryptColors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AirCryptColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: AirCryptColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AirCryptColors.accentCyan,
            width: 1.5,
          ),
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
