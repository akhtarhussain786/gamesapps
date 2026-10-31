import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'road_mesh.dart';
import 'traffic_cluster.dart';

/// Predicts where the car would touch down if FLY were released now, and
/// draws a reticle on the road there (green = clear, red = pile).
class LandingTarget {
  double predictedLandingZ = 0.0;
  bool isSafe = true;
  bool isActive = false;
  double _reticleSpin = 0.0;
  double _pulseTimer = 0.0;

  void update({
    required double dt,
    required double playerWx,
    required double playerWy,
    required double playerVy,
    required double playerWz,
    required double worldSpeed,
    required TrafficManager trafficManager,
  }) {
    _reticleSpin += dt * 3.5;
    _pulseTimer += dt * 6.0;

    isActive = playerWy > GameConstants.airborneThreshold;
    if (!isActive) {
      isSafe = true;
      return;
    }

    // Ballistic fall from the current height and vertical speed:
    // y(t) = h + vy*t - g*t²/2 = 0  ->  t = (vy + sqrt(vy² + 2gh)) / g
    const double g = GameConstants.flightGravity;
    final double vy = playerVy;
    final double timeToLand = (vy + math.sqrt(vy * vy + 2.0 * g * playerWy)) / g;
    predictedLandingZ = playerWz + worldSpeed * timeToLand;

    final bool offRoad = playerWx.abs() > GameConstants.roadHalfWidth * 0.88;
    final bool blocked = trafficManager.isLandingBlocked(playerWx: playerWx, landingZ: predictedLandingZ);
    isSafe = !offRoad && !blocked;
  }

  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double camZ,
    required double horizonY,
    required double playerWx,
    required RoadMesh roadMesh,
  }) {
    if (!isActive) return;

    final pt = roadMesh.project(
      wx: playerWx,
      wy: 0.0,
      wz: predictedLandingZ,
      size: size,
      camX: camX,
      camH: GameConstants.cameraHeight,
      camZ: camZ,
      camDepth: GameConstants.cameraDepth,
      horizonY: horizonY,
    );
    if (pt == null || pt.scale <= 0) return;

    final double w = pt.scale * GameConstants.playerCarWidth * 1.15 * (size.width * 0.5);
    if (w < 4.0) return;

    final double h = w * 0.3;
    final Color ringColor = isSafe ? GameConstants.neonGreen : GameConstants.neonRed;
    final double pulse = 0.9 + 0.1 * math.sin(_pulseTimer);
    final Rect ringRect = Rect.fromCenter(center: Offset(pt.x, pt.y), width: w * pulse, height: h * pulse);
    final double stroke = math.max(1.6, w * 0.025);

    canvas.drawOval(ringRect, Paint()..color = ringColor.withValues(alpha: 0.14 * pulse));
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = ringColor.withValues(alpha: 0.5 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.2
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, stroke * 1.5),
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Rotating tick marks (drawn in a squashed space so they lie on the road)
    final Paint tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(pt.x, pt.y);
    canvas.scale(1.0, h / w);
    final double r = w * 0.5 * pulse;
    for (int i = 0; i < 4; i++) {
      final double a = _reticleSpin + i * math.pi * 0.5;
      final Offset dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(dir * (r * 0.72), dir * (r * 0.92), tickPaint);
    }
    canvas.restore();
  }
}
