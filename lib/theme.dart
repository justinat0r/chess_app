import 'package:flutter/material.dart';

/// Shared colours and the app theme: dark walnut and brass, so the classic
/// board colours stay the brightest thing on screen.
class AppTheme {
  const AppTheme._();

  static const Color backgroundTop = Color(0xFF221D1A);
  static const Color backgroundBottom = Color(0xFF14100E);
  static const Color panel = Color(0xFF2C2521);
  static const Color accent = Color(0xFFD3A84C);
  static const Color textPrimary = Color(0xFFF3ECE1);
  static const Color textMuted = Color(0xFFB2A493);
  static const Color winGold = Color(0xFFE0B44E);
  static const Color drawSlate = Color(0xFF8FA3B0);

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: backgroundBottom,
      primary: accent,
      onPrimary: const Color(0xFF241B08),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundBottom,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
      ),
      textTheme: Typography.whiteMountainView.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: textPrimary,
          side: const BorderSide(color: Color(0x66D3A84C)),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  /// Background used by every screen.
  static const BoxDecoration backdrop = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[backgroundTop, backgroundBottom],
    ),
  );
}
