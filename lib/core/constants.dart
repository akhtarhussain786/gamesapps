import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Game-wide physical, mathematical, and design constants for ROADSTER RUSH.
class GameConstants {
  // ---------------------------------------------------------------------------
  // Camera & World Geometry (OutRun-style projection, see RoadMesh.project)
  // ---------------------------------------------------------------------------
  static const double roadHalfWidth = 1000.0;
  static const double segmentLength = 200.0;
  static const int drawSegments = 85;
  static const double cameraHeight = 560.0;
  static const double cameraDepth = 0.84;
  static const double horizonYRatio = 0.36;

  /// Where the player's tyres touch the road, as a fraction of screen height.
  static const double playerGroundYRatio = 0.80;

  /// World-space distance from the camera to the player's rear bumper.
  /// Derived from the projection so that the road point at this depth lands
  /// exactly on [playerGroundYRatio]. Collisions, the landing reticle and the
  /// drawn car therefore all agree on where the player is.
  static const double playerDepth =
      cameraDepth * cameraHeight * 0.5 / (playerGroundYRatio - horizonYRatio);

  /// World units travelled per second for each unit of `speed`.
  static const double worldUnitsPerSpeed = 25.0;

  /// Metres per world unit (used for the distance and km/h readouts).
  static const double metresPerWorldUnit = 0.05;

  // Lateral Movement & Clamping
  static const double lateralSpeed = 900.0;
  static const double roadMargin = 200.0; // clamp to [-roadHalfWidth + 200, roadHalfWidth - 200]

  // Lane Positions
  static const double laneLeft = -600.0;
  static const double laneCenter = 0.0;
  static const double laneRight = 600.0;
  static const List<double> lanes = [laneLeft, laneCenter, laneRight];

  // Speed Dynamics
  static const double startSpeed = 40.0;
  static const double maxSpeedCap = 160.0;
  static const double accelRate = 6.0;
  static const double brakeRate = 80.0;
  static const double maxDeltaTime = 1.0 / 30.0;

  // Flight & Physics
  static const double maxFlightAltitude = 400.0;
  static const double flightLiftAccel = 900.0;
  static const double flightGravity = 1400.0;
  static const double airMeterMax = 100.0;
  static const double airDrainRatePerSecond = 25.0;
  static const double airRefillRatePerSecond = 15.0;
  static const double airborneThreshold = 20.0;
  static const double flipDurationSeconds = 0.6;

  // Scoring
  static const int bonusStuntFlip = 50;
  static const int bonusPerfectLanding = 300;
  static const int bonusOverpassStack = 200;

  // Steering & Tilt
  static const double joystickRadius = 60.0;
  static const double joystickDeadZone = 0.10;
  static const double maxPlayerTiltRad = 4.0 * math.pi / 180.0;

  // ---------------------------------------------------------------------------
  // Vehicle dimensions (world units) & hit boxes
  // ---------------------------------------------------------------------------
  static const double trafficCarWidth = 420.0;
  static const double playerCarWidth = 460.0;

  /// Height of one car in a pile. Matches the drawn height of a traffic car on
  /// a typical phone, so "flying over" a pile visually clears it too.
  static const double carStackHeight = 105.0;

  /// Lateral overlap needed for a hit (forgiving: ~72% of the visual overlap).
  static const double hitHalfWidth = 0.72 * (trafficCarWidth + playerCarWidth) * 0.5;

  /// Depth window, relative to the player's rear bumper, in which an obstacle
  /// overlaps the player's car on screen.
  static const double hitDepthBehind = -60.0;
  static const double hitDepthAhead = 140.0;

  // Traffic Colors
  static const Color trafficWhite = Color(0xFFE6E9EE);
  static const Color trafficBlue = Color(0xFF2563C9);
  static const Color trafficRed = Color(0xFFC62A2A);
  static const Color trafficBlack = Color(0xFF22272E);
  static const List<Color> trafficColors = [
    trafficWhite,
    trafficBlue,
    trafficRed,
    trafficBlack,
  ];

  // ---------------------------------------------------------------------------
  // UI palette — each colour has ONE meaning
  // ---------------------------------------------------------------------------
  /// Systems & information (HUD, FLY, AIR).
  static const Color neonCyan = Color(0xFF22E4FF);
  static const Color neonAqua = Color(0xFF7DF3FF);

  /// Player brand colour (car paint, stunts, FLIP).
  static const Color playerMagenta = Color(0xFFFF2E88);
  static const Color playerMagentaDeep = Color(0xFF9E0F55);

  /// Caution.
  static const Color neonAmber = Color(0xFFFFB020);

  /// Danger.
  static const Color neonRed = Color(0xFFFF3B4E);

  /// Rewards.
  static const Color neonGreen = Color(0xFF3DFF9A);

  // Kept for backwards compatibility with older call sites.
  static const Color neonYellow = neonAmber;

  static const Color darkBlueGlow = Color(0xFF0B1630);
  static const Color bgDark = Color(0xFF070B14);
  static const Color panelFill = Color(0xD90A1222);
  static const Color panelStroke = Color(0x3322E4FF);
  static const Color textMuted = Color(0xFF8A9BB0);

  // Road Colors
  static const Color asphaltDark = Color(0xFF383C45);
  static const Color asphaltDarker = Color(0xFF2F333B);
  static const Color curbRed = Color(0xFFE53935);
  static const Color curbWhite = Color(0xFFFAFAFA);
  static const Color grassGreen = Color(0xFF3D8C40);
  static const Color grassDarkerGreen = Color(0xFF2E6B30);
  static const Color horizonFogColor = Color(0xFFB0BEC5);

  // Storage Keys
  static const String keyBestScore = 'rr_best_score';
  static const String keySoundEnabled = 'rr_sound_enabled';
}
