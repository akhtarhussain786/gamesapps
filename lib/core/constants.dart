import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Game-wide physical, mathematical, and design constants for ROADSTER RUSH.
class GameConstants {
  // OutRun-Style Camera & World Geometry
  static const double roadHalfWidth = 1000.0;
  static const double segmentLength = 200.0;
  static const int drawSegments = 85;
  static const double cameraHeight = 1000.0;
  static const double cameraDepth = 0.84;
  static const double horizonYRatio = 0.36;

  // Lateral Movement & Clamping
  static const double lateralSpeed = 900.0;
  static const double roadMargin = 200.0; // clamp to [-roadHalfWidth + 200, roadHalfWidth - 200]

  // Lane Positions
  static const double laneLeft = -600.0;
  static const double laneCenter = 0.0;
  static const double laneRight = 600.0;
  static const List<double> lanes = [laneLeft, laneCenter, laneRight];

  // Speed Dynamics (Issue 1)
  static const double startSpeed = 40.0;       // Start speed = 40 units/s
  static const double maxSpeedCap = 160.0;     // Capped at 160
  static const double accelRate = 6.0;         // accel = 6 units/s^2
  static const double brakeRate = 80.0;        // brake = 80 units/s^2
  static const double maxDeltaTime = 1.0 / 30.0; // Clamp dt to max 1/30

  // Flight & Physics (Issue 3)
  static const double maxFlightAltitude = 400.0; // max height 400
  static const double flightLiftAccel = 900.0;    // vy += 900*dt
  static const double flightGravity = 1400.0;     // vy -= 1400*dt
  static const double airMeterMax = 100.0;
  static const double airDrainRatePerSecond = 25.0;  // 25/s when held
  static const double airRefillRatePerSecond = 15.0; // 15/s on ground
  static const double flipDurationSeconds = 0.6;     // 0.6s
  static const int bonusStuntFlip = 50;              // +50 score
  static const int bonusPerfectLanding = 300;
  static const int bonusOverpassStack = 200;

  // Steering & Tilt
  static const double joystickRadius = 60.0;
  static const double joystickDeadZone = 0.10; // 10%
  static const double maxPlayerTiltRad = 8.0 * math.pi / 180.0; // max ±8 deg

  // Car Stacking & Dimensions
  static const double carStackHeight = 60.0; // wy += 60 per layer
  static const double playerHitboxWidth = 300.0;
  static const double playerHitboxDepth = 140.0;

  // Traffic Colors (Issue 4)
  static const Color trafficWhite = Color(0xFFEDEFF2);
  static const Color trafficBlue = Color(0xFF1E6FD9);
  static const Color trafficRed = Color(0xFFD92B2B);
  static const Color trafficBlack = Color(0xFF1E2329);
  static const List<Color> trafficColors = [
    trafficWhite,
    trafficBlue,
    trafficRed,
    trafficBlack,
  ];

  // UI & Theme Colors
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonAqua = Color(0xFF18FFFF);
  static const Color neonYellow = Color(0xFFFFD600);
  static const Color neonRed = Color(0xFFFF2D2D);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color darkBlueGlow = Color(0xFF09142A);
  static const Color bgDark = Color(0xFF070B14);

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
