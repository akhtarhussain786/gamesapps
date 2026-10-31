import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'roadster_painter.dart';

/// Where the player's car sits on screen this frame. Computed by the game from
/// the same projection used for the road and traffic, so what you see is what
/// collides.
class PlayerPose {
  /// Horizontal centre of the car.
  final double x;

  /// Screen Y where the road is directly under the car.
  final double groundY;

  /// Screen Y of the car's tyres (equals [groundY] when driving).
  final double carY;

  /// On-screen width of the car.
  final double width;

  /// 0 on the road, 1 at max altitude.
  final double altitudeRatio;

  const PlayerPose({
    required this.x,
    required this.groundY,
    required this.carY,
    required this.width,
    required this.altitudeRatio,
  });

  Offset get nozzleLeft => Offset(x - RoadsterPainter.nozzleX * width, carY + RoadsterPainter.nozzleY * width);
  Offset get nozzleRight => Offset(x + RoadsterPainter.nozzleX * width, carY + RoadsterPainter.nozzleY * width);
  double get height => width * RoadsterPainter.heightRatio;
}

/// Renders the player's roadster: ground shadow and light pool, body roll,
/// thruster jets and a pitch-axis stunt flip.
class PlayerCar {
  double currentTilt = 0.0;
  double _steer = 0.0;
  double _time = 0.0;
  double _thrust = 0.0;

  void update({
    required double dt,
    required double steerSmoothed,
    required bool isFlying,
  }) {
    _time += dt;
    _steer = steerSmoothed;
    currentTilt = steerSmoothed * GameConstants.maxPlayerTiltRad;
    // Ease thrusters in/out instead of popping.
    final double target = isFlying ? 1.0 : 0.0;
    _thrust += (target - _thrust) * math.min(1.0, dt * 12.0);
  }

  void render({
    required Canvas canvas,
    required PlayerPose pose,
    required double flipAngle,
    required bool isFlipping,
  }) {
    final double w = pose.width * (1.0 + pose.altitudeRatio * 0.06);
    final bool airborne = pose.altitudeRatio > 0.04;

    _drawGround(canvas, pose);

    canvas.save();
    canvas.translate(pose.x, pose.carY);

    if (isFlipping) {
      // Small hop arc while rotating.
      canvas.translate(0.0, -math.sin(flipAngle * 0.5) * 0.15 * w);
      _drawFlip(canvas, w, flipAngle);
    } else {
      // Roll around the car's centre of mass.
      final double pivotY = -0.25 * w;
      canvas.translate(0.0, pivotY);
      canvas.rotate(currentTilt);
      canvas.translate(0.0, -pivotY);
      RoadsterPainter.paintRear(
        canvas,
        w,
        steer: _steer,
        thrust: _thrust,
        time: _time,
        airborne: airborne,
      );
    }

    canvas.restore();
  }

  void _drawFlip(Canvas canvas, double w, double angle) {
    final double c = math.cos(angle);
    final double s = math.sin(angle);
    final double pivotY = -0.28 * w;

    if (c.abs() >= 0.35) {
      // Rear face foreshortened by the pitch (upside down past 90°).
      canvas.translate(0.0, pivotY);
      canvas.scale(1.0, c);
      canvas.translate(0.0, -pivotY);
      RoadsterPainter.paintRear(canvas, w, thrust: _thrust, time: _time, airborne: true);
    } else if (s > 0) {
      RoadsterPainter.paintTop(canvas, w, 0.62 * s.abs());
    } else {
      RoadsterPainter.paintUnderside(canvas, w, 0.62 * s.abs());
    }
  }

  void _drawGround(Canvas canvas, PlayerPose pose) {
    final double a = pose.altitudeRatio;
    final double w = pose.width;

    // Soft contact shadow: tight & dark on the road, wide & faint when high.
    final double shadowW = w * (1.08 - a * 0.25);
    final double shadowH = w * (0.13 - a * 0.03);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pose.x, pose.groundY - w * 0.01), width: shadowW, height: shadowH),
      Paint()
        ..color = Colors.black.withValues(alpha: (0.55 - a * 0.35).clamp(0.15, 0.55))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + a * 10.0),
    );

    // Cyan light on the asphalt: under-glow when driving, thruster wash when flying.
    final double glowAlpha = (0.22 + _thrust * 0.25) * (1.0 - a * 0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pose.x, pose.groundY - w * 0.02),
        width: w * (0.9 + _thrust * 0.3),
        height: w * 0.12,
      ),
      Paint()
        ..color = GameConstants.neonCyan.withValues(alpha: glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 + _thrust * 6.0),
    );
  }
}
