import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'road_mesh.dart';
import 'traffic_cluster.dart';

/// Real-time projected landing zone ring on the road surface at predicted landing Z.
class LandingTarget {
  double predictedLandingZ = 0.0;
  bool isSafe = true;
  double _reticleSpin = 0.0;
  double _pulseTimer = 0.0;

  void update({
    required double dt,
    required double playerWx,
    required double playerWy,
    required double camZ,
    required double speed,
    required TrafficManager trafficManager,
  }) {
    _reticleSpin += dt * 3.5;
    _pulseTimer += dt * 6.0;

    if (playerWy <= 20.0) {
      isSafe = true;
      return;
    }

    // Predict touchdown Z based on gravity descent
    final double timeToLand = math.sqrt((2.0 * playerWy) / GameConstants.flightGravity);
    predictedLandingZ = camZ + 800.0 + (speed * timeToLand);

    // 1. Off-road check
    if (playerWx.abs() > GameConstants.roadHalfWidth * 0.88) {
      isSafe = false;
      return;
    }

    // 2. Obstacle collision check
    bool hitTraffic = false;
    for (final car in trafficManager.cars) {
      final double dz = (car.wz - predictedLandingZ).abs();
      if (dz < 160.0) {
        final double dx = (car.wx - playerWx).abs();
        if (dx < 280.0) {
          hitTraffic = true;
          break;
        }
      }
    }

    isSafe = !hitTraffic;
  }

  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double camZ,
    required double horizonY,
    required double playerWx,
    required double playerWy,
    required RoadMesh roadMesh,
  }) {
    // Only visible when airborne
    if (playerWy <= 20.0) return;

    const double camH = GameConstants.cameraHeight;
    const double camDepth = GameConstants.cameraDepth;

    final pt = roadMesh.project(
      wx: playerWx,
      wy: 0.0, // On the road surface
      wz: predictedLandingZ,
      size: size,
      camX: camX,
      camH: camH,
      camZ: camZ,
      camDepth: camDepth,
      horizonY: horizonY,
    );

    if (pt == null || pt.scale <= 0) return;

    final double w = pt.scale * 800.0 * (size.width * 0.5);
    if (w < 4.0) return;

    final double h = w * 0.32;
    final Color ringColor = isSafe ? GameConstants.neonGreen : GameConstants.neonRed;
    final double pulse = 0.88 + 0.12 * math.sin(_pulseTimer);

    // Outer glow
    final Paint glowPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.45 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, pt.scale * 16.0)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, pt.scale * 12.0));

    // Core crisp ring
    final Paint ringPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, pt.scale * 8.0);

    // Fill highlight
    final Paint fillPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final Rect ringRect = Rect.fromCenter(
      center: Offset(pt.x, pt.y),
      width: w * pulse,
      height: h * pulse,
    );

    canvas.drawOval(ringRect, fillPaint);
    canvas.drawOval(ringRect, glowPaint);
    canvas.drawOval(ringRect, ringPaint);

    // Rotating crosshairs
    final Paint tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = math.max(1.5, pt.scale * 5.0);

    canvas.save();
    canvas.translate(pt.x, pt.y);
    canvas.rotate(_reticleSpin);

    final double tickX = (w * 0.5) * 0.28;
    canvas.drawLine(Offset(-w * 0.5, 0), Offset(-w * 0.5 + tickX, 0), tickPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5 - tickX, 0), tickPaint);
    canvas.drawLine(Offset(0, -h * 0.5), Offset(0, -h * 0.5 + tickX * 0.35), tickPaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(0, h * 0.5 - tickX * 0.35), tickPaint);

    canvas.restore();
  }
}
