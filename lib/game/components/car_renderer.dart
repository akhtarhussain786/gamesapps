import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Height of a traffic car's rear-view artwork as a fraction of its width.
const double trafficCarHeightRatio = 0.55;

/// Draws a rear-view traffic car whose tyres touch the road at [ground]
/// (bottom-centre). Traffic cars are deliberately plain, boxy sedans so the
/// player's roadster is always easy to pick out.
void drawTrafficCar(Canvas c, Offset ground, double w, Color body, {bool drawShadow = true}) {
  final double x = ground.dx;
  final double y = ground.dy;
  final bool detailed = w > 28.0;

  // 1. Contact shadow
  if (drawShadow) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y - w * 0.01), width: w * 1.06, height: w * 0.12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = detailed ? const MaskFilter.blur(BlurStyle.normal, 3.0) : null,
    );
  }

  // 2. Tyres (visible below the bumper)
  final Paint tyrePaint = Paint()..color = const Color(0xFF12161C);
  final double tyreW = w * 0.17;
  final double tyreH = w * 0.15;
  for (final double side in const [-1.0, 1.0]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + side * (w * 0.47) - (side < 0 ? 0 : tyreW), y - tyreH, tyreW, tyreH),
        Radius.circular(w * 0.03),
      ),
      tyrePaint,
    );
  }

  // 3. Rear panel
  final Color bodyDark = Color.lerp(body, Colors.black, 0.28)!;
  final Color bodyLight = Color.lerp(body, Colors.white, 0.18)!;
  final double bodyBottom = y - w * 0.07;
  final double bodyTop = y - w * 0.31;
  final Rect panel = Rect.fromLTRB(x - w * 0.49, bodyTop, x + w * 0.49, bodyBottom);
  c.drawRRect(
    RRect.fromRectAndRadius(panel, Radius.circular(w * 0.07)),
    Paint()..color = body,
  );
  // Lower bumper band
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(panel.left + w * 0.02, bodyBottom - w * 0.05, panel.right - w * 0.02, bodyBottom),
      Radius.circular(w * 0.03),
    ),
    Paint()..color = bodyDark,
  );

  // 4. Cabin (trapezoid) & rear window
  final double cabinTop = y - w * trafficCarHeightRatio;
  final Path cabin = Path()
    ..moveTo(x - w * 0.40, bodyTop + 1.0)
    ..lineTo(x - w * 0.30, cabinTop)
    ..lineTo(x + w * 0.30, cabinTop)
    ..lineTo(x + w * 0.40, bodyTop + 1.0)
    ..close();
  c.drawPath(cabin, Paint()..color = Color.lerp(body, Colors.black, 0.18)!);

  final Path window = Path()
    ..moveTo(x - w * 0.34, bodyTop - w * 0.015)
    ..lineTo(x - w * 0.27, cabinTop + w * 0.03)
    ..lineTo(x + w * 0.27, cabinTop + w * 0.03)
    ..lineTo(x + w * 0.34, bodyTop - w * 0.015)
    ..close();
  c.drawPath(window, Paint()..color = const Color(0xFF1A2430));

  if (detailed) {
    // Roof highlight & window reflection
    c.drawLine(
      Offset(x - w * 0.28, cabinTop + 0.5),
      Offset(x + w * 0.28, cabinTop + 0.5),
      Paint()
        ..color = bodyLight
        ..strokeWidth = math.max(1.0, w * 0.012),
    );
    c.drawLine(
      Offset(x - w * 0.16, bodyTop - w * 0.03),
      Offset(x - w * 0.04, cabinTop + w * 0.05),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = math.max(1.0, w * 0.02),
    );
  }

  // 5. Taillights
  final double tailY = bodyTop + w * 0.05;
  final double tailW = w * 0.17;
  final double tailH = w * 0.065;
  const Color tail = Color(0xFFFF2D2D);
  for (final double side in const [-1.0, 1.0]) {
    final Rect r = Rect.fromLTWH(
      side < 0 ? x - w * 0.45 : x + w * 0.45 - tailW,
      tailY,
      tailW,
      tailH,
    );
    if (detailed) {
      c.drawRRect(
        RRect.fromRectAndRadius(r.inflate(w * 0.01), Radius.circular(w * 0.03)),
        Paint()
          ..color = tail.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(1.5, w * 0.03)),
      );
    }
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * 0.02)), Paint()..color = tail);
  }

  // 6. License plate
  if (detailed) {
    final Rect plate = Rect.fromCenter(
      center: Offset(x, bodyBottom - w * 0.1),
      width: w * 0.2,
      height: w * 0.065,
    );
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F4F7));
    c.drawRect(
      plate,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}
