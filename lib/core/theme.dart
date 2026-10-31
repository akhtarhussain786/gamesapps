import 'package:flutter/material.dart';
import 'constants.dart';

/// Bundled font families (see pubspec.yaml). Bundling them makes the game look
/// identical on Android, iOS, web and desktop instead of falling back to
/// whatever generic "monospace" font each platform happens to ship.
class GameFonts {
  /// Chunky display face for logos, headings, countdown and buttons.
  static const String display = 'RussoOne';

  /// Condensed techno face for labels and body copy.
  static const String ui = 'Rajdhani';

  /// Fixed-width digits for numeric readouts (score, speed, distance).
  static const String digits = 'ShareTechMono';
}

class GameTheme {
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GameConstants.bgDark,
      primaryColor: GameConstants.neonCyan,
      fontFamily: GameFonts.ui,
      colorScheme: const ColorScheme.dark(
        primary: GameConstants.neonCyan,
        secondary: GameConstants.playerMagenta,
        surface: GameConstants.darkBlueGlow,
        error: GameConstants.neonRed,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text styles
  // ---------------------------------------------------------------------------

  /// Big numeric readout (score).
  static const TextStyle numberLarge = TextStyle(
    fontFamily: GameFonts.digits,
    fontSize: 30,
    height: 1.0,
    letterSpacing: 1.5,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Medium numeric readout (speed).
  static const TextStyle numberMedium = TextStyle(
    fontFamily: GameFonts.digits,
    fontSize: 22,
    height: 1.0,
    letterSpacing: 1.0,
    color: Colors.white,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Small numeric readout (distance, stats).
  static const TextStyle numberSmall = TextStyle(
    fontFamily: GameFonts.digits,
    fontSize: 13,
    height: 1.0,
    letterSpacing: 0.5,
    color: Color(0xFFCFD8E3),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Tiny all-caps caption above a value ("SCORE", "KM/H").
  static const TextStyle caption = TextStyle(
    fontFamily: GameFonts.ui,
    fontSize: 11,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: GameConstants.textMuted,
  );

  /// Standard label (chips, buttons on panels).
  static const TextStyle label = TextStyle(
    fontFamily: GameFonts.ui,
    fontSize: 14,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: Colors.white,
  );

  /// Button / heading text.
  static const TextStyle button = TextStyle(
    fontFamily: GameFonts.display,
    fontSize: 16,
    height: 1.0,
    letterSpacing: 2.0,
    color: Colors.white,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: GameFonts.display,
    fontSize: 26,
    height: 1.0,
    letterSpacing: 3.0,
    color: Colors.white,
  );

  static const TextStyle logoTitle = TextStyle(
    fontFamily: GameFonts.display,
    fontSize: 44,
    height: 1.0,
    fontStyle: FontStyle.italic,
    letterSpacing: 2.0,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0x6622E4FF), blurRadius: 18.0),
    ],
  );

  // Legacy aliases (kept so older widgets keep compiling).
  static const TextStyle lcdLarge = numberLarge;
  static const TextStyle lcdMedium = numberMedium;
  static const TextStyle lcdSmall = numberSmall;

  // ---------------------------------------------------------------------------
  // Panels
  // ---------------------------------------------------------------------------

  /// Translucent dark panel. Glow is kept subtle so that only genuinely
  /// important elements (primary buttons, warnings) stand out.
  static BoxDecoration glassPanel({Color? borderColor, double borderRadius = 14.0, bool glow = false}) {
    final Color stroke = borderColor ?? GameConstants.neonCyan;
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xE00E1A2E), Color(0xE0070D19)],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: stroke.withValues(alpha: 0.28), width: 1.0),
      boxShadow: [
        const BoxShadow(color: Color(0x66000000), blurRadius: 12.0, offset: Offset(0, 4)),
        if (glow) BoxShadow(color: stroke.withValues(alpha: 0.22), blurRadius: 18.0),
      ],
    );
  }
}
