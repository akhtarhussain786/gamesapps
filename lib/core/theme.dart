import 'package:flutter/material.dart';
import 'constants.dart';

class GameTheme {
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameConstants.bgDark,
      primaryColor: GameConstants.neonCyan,
      fontFamily: 'monospace',
      colorScheme: const ColorScheme.dark(
        primary: GameConstants.neonCyan,
        secondary: GameConstants.neonAqua,
        surface: GameConstants.darkBlueGlow,
        error: GameConstants.neonRed,
      ),
    );
  }

  // Monospace LCD Number Styles
  static const TextStyle lcdLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 3.0,
    color: GameConstants.neonCyan,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [
      Shadow(
        color: GameConstants.neonCyan,
        blurRadius: 10.0,
      ),
      Shadow(
        color: Color(0x8000F0FF),
        blurRadius: 20.0,
      ),
    ],
  );

  static const TextStyle lcdMedium = TextStyle(
    fontFamily: 'monospace',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [
      Shadow(
        color: GameConstants.neonCyan,
        blurRadius: 8.0,
      ),
    ],
  );

  static const TextStyle lcdSmall = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: Color(0xFFB0BEC5),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle logoTitle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 42,
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    letterSpacing: 5.0,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Color(0xAAFFFFFF),
        blurRadius: 14.0,
      ),
      Shadow(
        color: GameConstants.neonCyan,
        blurRadius: 28.0,
      ),
    ],
  );

  // Reusable Translucent Dark Panel Decoration
  static BoxDecoration glassPanel({Color? borderColor, double borderRadius = 12.0}) {
    return BoxDecoration(
      color: const Color(0xCC09101E),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? GameConstants.neonCyan).withValues(alpha: 0.35),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? GameConstants.neonCyan).withValues(alpha: 0.15),
          blurRadius: 16.0,
          spreadRadius: 1.0,
        ),
      ],
    );
  }
}
