import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'car_renderer.dart';

/// Renders the player roadster at fixed bottom-center (screenY ≈ height * 0.78).
/// Uses drawCar with player=true (neon cyan underglow, spoiler line),
/// max ±8° steering tilt, and vertical climb with ground-anchored shadow during flight.
class PlayerCar {
  double currentTilt = 0.0;
  double _thrusterTimer = 0.0;

  void update({
    required double dt,
    required double steerSmoothed,
    required bool isFlying,
  }) {
    _thrusterTimer += dt * 30.0;
    // Tilts max ±8 degrees based on steering
    currentTilt = steerSmoothed * GameConstants.maxPlayerTiltRad;
  }

  void render({
    required Canvas canvas,
    required Size size,
    required double wy,
    required double flipAngle,
    required bool isFlying,
    required bool isFlipping,
  }) {
    final double screenX = size.width * 0.5;
    // Perfectly positioned above the bottom joystick and fly buttons (around 70% screen height)
    final double baseGroundY = size.height * 0.70;

    final double altRatio = (wy / GameConstants.maxFlightAltitude).clamp(0.0, 1.0);
    // FLY: raise player wy (sprite moves up + scales slightly)
    final double carScreenY = baseGroundY - (altRatio * size.height * 0.28);
    final double carScale = 1.0 + (altRatio * 0.18);
    const double baseWidth = 148.0; // Scaled to sit cleanly in center lane without overlapping controls
    final double w = baseWidth * carScale;

    // 1. Shadow stays on the ground road surface
    _drawGroundShadow(canvas, screenX, baseGroundY, w, altRatio);

    // Save canvas for player transformation
    canvas.save();
    canvas.translate(screenX, carScreenY);

    // Apply tilt (max ±8 deg) or 360° stunt flip
    if (isFlipping) {
      canvas.rotate(flipAngle);
    } else {
      canvas.rotate(currentTilt);
    }

    // 2. Twin Plasma Thrusters (when flying)
    if (isFlying || wy > 10.0) {
      _drawThrusters(canvas, w, isFlying);
    }

    // 3. Main Player Car using unified drawCar (body color white, player: true)
    drawCar(
      canvas,
      Offset.zero,
      w,
      GameConstants.trafficWhite,
      player: true,
    );

    canvas.restore();
  }

  void _drawGroundShadow(Canvas canvas, double sx, double groundY, double w, double altRatio) {
    final double shadowScale = 1.0 + (altRatio * 0.45);
    final double shadowOpacity = (0.50 - altRatio * 0.38).clamp(0.12, 0.50);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + (altRatio * 16.0));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sx, groundY + 8.0),
        width: w * 1.1 * shadowScale,
        height: (w * 0.55 * 0.26) * shadowScale,
      ),
      shadowPaint,
    );
  }

  void _drawThrusters(Canvas canvas, double w, bool isBoosting) {
    final double h = w * 0.55;
    final double flicker = math.sin(_thrusterTimer) * 5.0 + math.cos(_thrusterTimer * 1.6) * 4.0;
    final double flameLen = (isBoosting ? 65.0 : 28.0) + flicker;
    final double flameW = isBoosting ? 18.0 : 9.0;
    final double thrusterY = h * 0.40;

    final Paint coreFlame = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, GameConstants.neonCyan, Color(0x0000E5FF)],
      ).createShader(Rect.fromLTWH(-55, thrusterY, 110, flameLen));

    final Paint outerGlow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GameConstants.neonAqua, Color(0x550055FF), Colors.transparent],
      ).createShader(Rect.fromLTWH(-60, thrusterY, 120, flameLen + 18))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Left Jet
    final Path leftJet = Path()
      ..moveTo(-w * 0.28 - flameW * 0.5, thrusterY)
      ..lineTo(-w * 0.28 + flameW * 0.5, thrusterY)
      ..lineTo(-w * 0.28, thrusterY + flameLen)
      ..close();
    canvas.drawPath(leftJet, outerGlow);
    canvas.drawPath(leftJet, coreFlame);

    // Right Jet
    final Path rightJet = Path()
      ..moveTo(w * 0.28 - flameW * 0.5, thrusterY)
      ..lineTo(w * 0.28 + flameW * 0.5, thrusterY)
      ..lineTo(w * 0.28, thrusterY + flameLen)
      ..close();
    canvas.drawPath(rightJet, outerGlow);
    canvas.drawPath(rightJet, coreFlame);
  }
}
