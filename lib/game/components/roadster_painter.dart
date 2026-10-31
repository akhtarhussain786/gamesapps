import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Vector artwork for the player's electric roadster.
///
/// All functions draw in a local coordinate space whose origin is the point
/// where the car touches the road (bottom-centre), with negative Y going up.
/// `w` is the car's on-screen width in pixels; every coordinate is a fraction
/// of `w` so the car stays crisp at any size.
///
/// Silhouette (rear view): wide tyres visible either side of a carbon
/// diffuser with two plasma thruster nozzles, muscular rear haunches, a
/// full-width LED light bar, twin roadster humps behind a tinted canopy, and a
/// GT wing on struts.
class RoadsterPainter {
  static const Color _paintTop = Color(0xFFFF6AB0);
  static const Color _paintMid = GameConstants.playerMagenta;
  static const Color _paintLow = Color(0xFFC0156B);
  static const Color _paintShadow = Color(0xFF6E0A3E);
  static const Color _carbon = Color(0xFF10141B);
  static const Color _carbonEdge = Color(0xFF2B3442);
  static const Color _tyre = Color(0xFF0C0F14);
  static const Color _light = Color(0xFFFF2D4B);

  /// Total height of the rear-view artwork as a fraction of width.
  static const double heightRatio = 0.555;

  /// Height (fraction of w, negative = up) of the thruster nozzles.
  static const double nozzleY = -0.093;

  /// Lateral offset (fraction of w) of each thruster nozzle.
  static const double nozzleX = 0.15;

  // ---------------------------------------------------------------------------
  // Rear view
  // ---------------------------------------------------------------------------

  /// [steer] in -1..1 reveals a sliver of the car's flank for a sense of yaw.
  /// [thrust] 0 = idle nozzles, 1 = full lift (big plasma jets).
  /// [time] drives the flame flicker.
  static void paintRear(
    Canvas c,
    double w, {
    double steer = 0.0,
    double thrust = 0.0,
    double time = 0.0,
    bool airborne = false,
  }) {
    _paintTyres(c, w);

    final Path body = _bodyPath(w);

    // Flank sliver on the side facing the camera while turning.
    if (steer.abs() > 0.02) {
      final double shift = -steer * 0.05 * w;
      c.drawPath(body.shift(Offset(shift, 0.0)), Paint()..color = _paintShadow);
    }

    // Main painted body.
    final Rect bodyRect = Rect.fromLTRB(-0.52 * w, -0.33 * w, 0.52 * w, -0.06 * w);
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_paintTop, _paintMid, _paintLow, _paintShadow],
          stops: [0.0, 0.32, 0.72, 1.0],
        ).createShader(bodyRect),
    );

    // Haunch shading: darker towards the outer edges for a rounded look.
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.35),
          ],
          stops: const [0.0, 0.18, 0.82, 1.0],
        ).createShader(bodyRect),
    );

    // Shoulder specular line.
    c.drawLine(
      Offset(-0.40 * w, -0.304 * w),
      Offset(0.40 * w, -0.304 * w),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = math.max(1.0, 0.008 * w)
        ..strokeCap = StrokeCap.round,
    );

    _paintCanopy(c, w);
    _paintHumps(c, w);
    _paintLightBar(c, w);
    _paintRearDetails(c, w);
    _paintDiffuser(c, w, thrust);
    _paintWing(c, w);

    if (thrust > 0.0 || airborne) {
      _paintThrusterJets(c, w, airborne ? math.max(thrust, 0.25) : thrust, time);
    }
  }

  static Path _bodyPath(double w) {
    // Left half, top to bottom, then mirrored.
    final Path p = Path()
      ..moveTo(-0.30 * w, -0.06 * w)
      ..lineTo(-0.32 * w, -0.085 * w)
      ..lineTo(-0.33 * w, -0.17 * w)
      ..lineTo(-0.345 * w, -0.19 * w)
      ..lineTo(-0.49 * w, -0.19 * w)
      ..quadraticBezierTo(-0.522 * w, -0.205 * w, -0.515 * w, -0.24 * w)
      ..lineTo(-0.50 * w, -0.275 * w)
      ..quadraticBezierTo(-0.48 * w, -0.305 * w, -0.43 * w, -0.312 * w)
      ..lineTo(-0.30 * w, -0.325 * w)
      ..lineTo(0.30 * w, -0.325 * w)
      ..lineTo(0.43 * w, -0.312 * w)
      ..quadraticBezierTo(0.48 * w, -0.305 * w, 0.50 * w, -0.275 * w)
      ..lineTo(0.515 * w, -0.24 * w)
      ..quadraticBezierTo(0.522 * w, -0.205 * w, 0.49 * w, -0.19 * w)
      ..lineTo(0.345 * w, -0.19 * w)
      ..lineTo(0.33 * w, -0.17 * w)
      ..lineTo(0.32 * w, -0.085 * w)
      ..lineTo(0.30 * w, -0.06 * w)
      ..close();
    return p;
  }

  static void _paintTyres(Canvas c, double w) {
    final Paint tyrePaint = Paint()
      ..shader = const LinearGradient(
        colors: [_tyre, Color(0xFF232A35), _tyre],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(-0.5 * w, -0.2 * w, 0.5 * w, 0.0));
    final Paint treadPaint = Paint()
      ..color = const Color(0xFF323B48)
      ..strokeWidth = math.max(1.0, 0.007 * w);

    for (final double side in const [-1.0, 1.0]) {
      final Rect r = Rect.fromLTRB(
        side < 0 ? -0.50 * w : 0.33 * w,
        -0.205 * w,
        side < 0 ? -0.33 * w : 0.50 * w,
        0.0,
      );
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(0.04 * w)), tyrePaint);
      // Tread grooves
      for (int i = 1; i <= 3; i++) {
        final double y = -0.035 * w * i;
        c.drawLine(Offset(r.left + 0.02 * w, y), Offset(r.right - 0.02 * w, y), treadPaint);
      }
    }
  }

  static void _paintCanopy(Canvas c, double w) {
    final Path canopy = Path()
      ..moveTo(-0.215 * w, -0.32 * w)
      ..cubicTo(-0.20 * w, -0.43 * w, -0.12 * w, -0.47 * w, 0.0, -0.47 * w)
      ..cubicTo(0.12 * w, -0.47 * w, 0.20 * w, -0.43 * w, 0.215 * w, -0.32 * w)
      ..close();
    c.drawPath(
      canopy,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB6E6), Color(0xFF1C3150), Color(0xFF0A111C)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTRB(-0.22 * w, -0.47 * w, 0.22 * w, -0.32 * w)),
    );
    // Reflection streak
    final Path streak = Path()
      ..moveTo(-0.16 * w, -0.405 * w)
      ..quadraticBezierTo(-0.11 * w, -0.455 * w, -0.02 * w, -0.46 * w);
    c.drawPath(
      streak,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, 0.012 * w)
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _paintHumps(Canvas c, double w) {
    // Twin roadster fairings behind the seats: low, wide and in the wing's
    // shadow, so they read as bodywork rather than two bright bubbles.
    final Rect r = Rect.fromLTRB(-0.2 * w, -0.375 * w, 0.2 * w, -0.32 * w);
    final Paint humpPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_paintMid, _paintLow, _paintShadow],
        stops: [0.0, 0.55, 1.0],
      ).createShader(r);
    final Path humps = Path()
      ..moveTo(-0.205 * w, -0.322 * w)
      ..cubicTo(-0.19 * w, -0.372 * w, -0.03 * w, -0.376 * w, -0.012 * w, -0.345 * w)
      ..lineTo(0.012 * w, -0.345 * w)
      ..cubicTo(0.03 * w, -0.376 * w, 0.19 * w, -0.372 * w, 0.205 * w, -0.322 * w)
      ..close();
    c.drawPath(humps, humpPaint);
    // Top-edge highlight on each fairing
    final Paint rim = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, 0.006 * w)
      ..strokeCap = StrokeCap.round;
    for (final double side in const [-1.0, 1.0]) {
      final Path edge = Path()
        ..moveTo(side * 0.17 * w, -0.352 * w)
        ..quadraticBezierTo(side * 0.11 * w, -0.371 * w, side * 0.05 * w, -0.362 * w);
      c.drawPath(edge, rim);
    }
  }

  static void _paintLightBar(Canvas c, double w) {
    final Rect bar = Rect.fromLTRB(-0.44 * w, -0.262 * w, 0.44 * w, -0.238 * w);
    // Bloom
    c.drawRRect(
      RRect.fromRectAndRadius(bar.inflate(0.01 * w), Radius.circular(0.02 * w)),
      Paint()
        ..color = _light.withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, 0.03 * w)),
    );
    // Bar
    c.drawRRect(
      RRect.fromRectAndRadius(bar, Radius.circular(0.012 * w)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF7A8C), _light, Color(0xFFB0102A), _light, Color(0xFFFF7A8C)],
          stops: [0.0, 0.18, 0.5, 0.82, 1.0],
        ).createShader(bar),
    );
    // C-shaped signature at both ends
    final Paint sig = Paint()..color = const Color(0xFFFFB3BD);
    for (final double side in const [-1.0, 1.0]) {
      final double x = side * 0.455 * w;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, -0.232 * w), width: 0.022 * w, height: 0.06 * w),
          Radius.circular(0.01 * w),
        ),
        sig,
      );
    }
  }

  static void _paintRearDetails(Canvas c, double w) {
    // Recessed centre panel with two cyan accent slits
    final Rect recess = Rect.fromLTRB(-0.15 * w, -0.215 * w, 0.15 * w, -0.155 * w);
    c.drawRRect(
      RRect.fromRectAndRadius(recess, Radius.circular(0.015 * w)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    final Paint accent = Paint()
      ..color = GameConstants.neonCyan.withValues(alpha: 0.9)
      ..strokeWidth = math.max(1.0, 0.008 * w)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-0.11 * w, -0.185 * w), Offset(-0.03 * w, -0.185 * w), accent);
    c.drawLine(Offset(0.03 * w, -0.185 * w), Offset(0.11 * w, -0.185 * w), accent);
  }

  static void _paintDiffuser(Canvas c, double w, double thrust) {
    final Path diffuser = Path()
      ..moveTo(-0.30 * w, -0.06 * w)
      ..lineTo(-0.27 * w, -0.128 * w)
      ..lineTo(0.27 * w, -0.128 * w)
      ..lineTo(0.30 * w, -0.06 * w)
      ..close();
    c.drawPath(diffuser, Paint()..color = _carbon);

    final Paint fin = Paint()
      ..color = _carbonEdge
      ..strokeWidth = math.max(1.0, 0.008 * w);
    for (final double x in const [-0.22, -0.075, 0.075, 0.22]) {
      c.drawLine(Offset(x * w, -0.124 * w), Offset(x * w * 1.06, -0.064 * w), fin);
    }

    // Thruster nozzles
    final double glow = 0.35 + 0.65 * thrust.clamp(0.0, 1.0);
    for (final double side in const [-1.0, 1.0]) {
      final Offset ctr = Offset(side * nozzleX * w, nozzleY * w);
      final Rect nozzle = Rect.fromCenter(center: ctr, width: 0.10 * w, height: 0.05 * w);
      c.drawOval(
        nozzle.inflate(0.012 * w),
        Paint()
          ..color = GameConstants.neonCyan.withValues(alpha: 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, 0.02 * w)),
      );
      c.drawOval(nozzle, Paint()..color = const Color(0xFF05080C));
      c.drawOval(
        nozzle,
        Paint()
          ..color = Color.lerp(const Color(0xFF3A6E7A), GameConstants.neonCyan, glow)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.01 * w),
      );
      c.drawOval(
        nozzle.deflate(0.015 * w),
        Paint()..color = Color.lerp(const Color(0xFF0E2A33), const Color(0xFFE8FDFF), thrust.clamp(0.0, 1.0))!,
      );
    }
  }

  static void _paintWing(Canvas c, double w) {
    final Paint strut = Paint()
      ..color = _carbon
      ..strokeWidth = math.max(1.5, 0.024 * w)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-0.30 * w, -0.33 * w), Offset(-0.27 * w, -0.50 * w), strut);
    c.drawLine(Offset(0.30 * w, -0.33 * w), Offset(0.27 * w, -0.50 * w), strut);

    final Rect blade = Rect.fromLTRB(-0.47 * w, -0.535 * w, 0.47 * w, -0.497 * w);
    c.drawRRect(
      RRect.fromRectAndRadius(blade, Radius.circular(0.012 * w)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B4658), _carbon],
        ).createShader(blade),
    );
    // Magenta trailing-edge stripe ties the wing to the body colour.
    c.drawLine(
      Offset(-0.44 * w, -0.5 * w),
      Offset(0.44 * w, -0.5 * w),
      Paint()
        ..color = _paintMid
        ..strokeWidth = math.max(1.0, 0.007 * w),
    );
    // End plates
    final Paint plate = Paint()..color = const Color(0xFF1A2029);
    for (final double side in const [-1.0, 1.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(side * 0.468 * w, -0.52 * w), width: 0.028 * w, height: 0.075 * w),
          Radius.circular(0.008 * w),
        ),
        plate,
      );
    }
  }

  static void _paintThrusterJets(Canvas c, double w, double thrust, double time) {
    final double flicker = math.sin(time * 31.0) * 0.025 + math.cos(time * 47.0) * 0.02;
    final double len = (0.14 + 0.36 * thrust + flicker) * w;
    final double halfW = (0.03 + 0.025 * thrust) * w;

    for (final double side in const [-1.0, 1.0]) {
      final double x = side * nozzleX * w;
      final double top = nozzleY * w;
      final Rect bounds = Rect.fromLTRB(x - halfW * 2, top, x + halfW * 2, top + len);

      final Path jet = Path()
        ..moveTo(x - halfW, top)
        ..quadraticBezierTo(x - halfW * 0.9, top + len * 0.45, x, top + len)
        ..quadraticBezierTo(x + halfW * 0.9, top + len * 0.45, x + halfW, top)
        ..close();

      c.drawPath(
        jet,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameConstants.neonAqua, Color(0x8800A8FF), Color(0x0000A8FF)],
          ).createShader(bounds)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, 0.025 * w)),
      );
      c.drawPath(
        jet,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, GameConstants.neonCyan, Color(0x0022E4FF)],
            stops: [0.0, 0.4, 1.0],
          ).createShader(bounds),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Flip views (seen briefly while the car rotates)
  // ---------------------------------------------------------------------------

  /// Roof seen from above. [depth] is the projected length (fraction of w).
  static void paintTop(Canvas c, double w, double depth) {
    final double cy = -0.28 * w;
    final double h = math.max(0.02, depth) * w;
    final Rect r = Rect.fromCenter(center: Offset(0, cy), width: 0.98 * w, height: h);
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(math.min(0.12 * w, h * 0.5))),
      Paint()
        ..shader = const LinearGradient(
          colors: [_paintShadow, _paintMid, _paintTop, _paintMid, _paintShadow],
        ).createShader(r),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(0, cy), width: 0.42 * w, height: h * 0.45),
      Paint()..color = const Color(0xFF15253C),
    );
    c.drawRect(
      Rect.fromLTRB(-0.47 * w, r.bottom - h * 0.12, 0.47 * w, r.bottom - h * 0.02),
      Paint()..color = _carbon,
    );
  }

  /// Underside seen from below, with the four tyres and lit thrusters.
  static void paintUnderside(Canvas c, double w, double depth) {
    final double cy = -0.28 * w;
    final double h = math.max(0.02, depth) * w;
    final Rect r = Rect.fromCenter(center: Offset(0, cy), width: 0.92 * w, height: h);
    final double radius = math.min(0.08 * w, h * 0.5);

    // Magenta side skirts frame a lighter carbon floor pan.
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), Paint()..color = _paintLow);
    final Rect floor = r.deflate(0.035 * w);
    c.drawRRect(
      RRect.fromRectAndRadius(floor, Radius.circular(math.max(0.0, radius - 0.03 * w))),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1C232E), Color(0xFF2C3644), Color(0xFF1C232E)],
        ).createShader(floor),
    );

    // Tyres with a lighter tread face so they read against the floor.
    final Paint tyre = Paint()..color = _tyre;
    final Paint tread = Paint()..color = const Color(0xFF3A4452);
    for (final double sx in const [-1.0, 1.0]) {
      for (final double sy in const [-1.0, 1.0]) {
        final Rect t = Rect.fromCenter(
          center: Offset(sx * 0.42 * w, cy + sy * h * 0.3),
          width: 0.17 * w,
          height: h * 0.3,
        );
        c.drawRRect(RRect.fromRectAndRadius(t, Radius.circular(0.03 * w)), tyre);
        c.drawRect(t.deflate(math.min(0.03 * w, t.height * 0.3)), tread);
      }
    }

    // Glowing thruster rings
    final Paint ring = Paint()
      ..color = GameConstants.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, 0.014 * w);
    final Paint ringGlow = Paint()
      ..color = GameConstants.neonCyan.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(2.0, 0.025 * w));
    for (final double sx in const [-1.0, 1.0]) {
      final Rect o = Rect.fromCenter(center: Offset(sx * 0.15 * w, cy), width: 0.13 * w, height: h * 0.28);
      c.drawOval(o, ringGlow);
      c.drawOval(o, ring);
    }
  }
}
