import 'package:flutter/material.dart';

/// Unified reusable car drawing function for both traffic and player roadster.
/// Draws strict rear-view vehicles with shadow, wheels, lower body, cabin, rear window,
/// glowing taillights, license plate, and optional player underglow & spoiler.
void drawCar(Canvas c, Offset center, double w, Color body, {bool player = false}) {
  final double h = w * 0.55;

  // 1. Shadow: dark oval under car, width w * 1.1
  final Paint shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
  c.drawOval(
    Rect.fromCenter(
      center: Offset(center.dx, center.dy + h * 0.48),
      width: w * 1.1,
      height: h * 0.26,
    ),
    shadowPaint,
  );

  // 2. Player: neon cyan underglow (blur 14)
  if (player) {
    final Paint underglowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + h * 0.42),
        width: w * 1.15,
        height: h * 0.38,
      ),
      underglowPaint,
    );
  }

  // 3. Wheels: 2 dark RRect at the bottom corners, size w * 0.18 x h * 0.28
  final Paint wheelPaint = Paint()..color = const Color(0xFF141922);
  final double wheelW = w * 0.18;
  final double wheelH = h * 0.28;
  final Radius wheelRadius = Radius.circular(w * 0.04);

  // Left wheel
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.38, center.dy + h * 0.36),
        width: wheelW,
        height: wheelH,
      ),
      wheelRadius,
    ),
    wheelPaint,
  );

  // Right wheel
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx + w * 0.38, center.dy + h * 0.36),
        width: wheelW,
        height: wheelH,
      ),
      wheelRadius,
    ),
    wheelPaint,
  );

  // 4. Lower body: RRect (width w, height h * 0.55) with body color, radius w * 0.08
  final double bodyH = h * 0.55;
  final double bodyTop = center.dy + h * 0.50 - bodyH;
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - w * 0.5, bodyTop, w, bodyH),
      Radius.circular(w * 0.08),
    ),
    Paint()..color = body,
  );

  // 5. Cabin: trapezoid Path above the body, width w * 0.7 -> w * 0.55, color body darkened 25%
  final Color cabinColor = Color.fromARGB(
    (body.a * 255.0).round().clamp(0, 255),
    ((body.r * 255.0) * 0.75).round().clamp(0, 255),
    ((body.g * 255.0) * 0.75).round().clamp(0, 255),
    ((body.b * 255.0) * 0.75).round().clamp(0, 255),
  );

  final double cabinBottomW = w * 0.70;
  final double cabinTopW = w * 0.55;
  final double cabinBottomY = bodyTop + 2.0;
  final double cabinTopY = center.dy - h * 0.50;

  final Path cabinPath = Path()
    ..moveTo(center.dx - cabinBottomW * 0.5, cabinBottomY)
    ..lineTo(center.dx - cabinTopW * 0.5, cabinTopY)
    ..lineTo(center.dx + cabinTopW * 0.5, cabinTopY)
    ..lineTo(center.dx + cabinBottomW * 0.5, cabinBottomY)
    ..close();

  c.drawPath(cabinPath, Paint()..color = cabinColor);

  // 6. Rear window: RRect inside the cabin, color 0xFF1B2733, with a light diagonal highlight
  final double winW = cabinTopW * 0.90;
  final double winH = (cabinBottomY - cabinTopY) * 0.75;
  final Rect winRect = Rect.fromCenter(
    center: Offset(center.dx, cabinTopY + winH * 0.65),
    width: winW,
    height: winH,
  );

  c.drawRRect(
    RRect.fromRectAndRadius(winRect, Radius.circular(w * 0.04)),
    Paint()..color = const Color(0xFF1B2733),
  );

  // Diagonal window highlight
  final Paint highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.18)
    ..strokeWidth = 1.8;
  c.drawLine(
    Offset(winRect.left + winW * 0.25, winRect.bottom - 2),
    Offset(winRect.left + winW * 0.55, winRect.top + 2),
    highlightPaint,
  );

  // 7. Taillights: 2 red RRects (0xFFFF2D2D) at the body's two ends, with a glow (MaskFilter.blur 6)
  final double tailW = w * 0.18;
  final double tailH = bodyH * 0.32;
  final double tailY = bodyTop + bodyH * 0.24;
  final Radius tailRadius = Radius.circular(w * 0.04);

  final Rect leftTailRect = Rect.fromLTWH(center.dx - w * 0.47, tailY, tailW, tailH);
  final Rect rightTailRect = Rect.fromLTWH(center.dx + w * 0.47 - tailW, tailY, tailW, tailH);

  // Taillight glow
  final Paint tailGlowPaint = Paint()
    ..color = const Color(0xFFFF2D2D)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
  c.drawRRect(RRect.fromRectAndRadius(leftTailRect, tailRadius), tailGlowPaint);
  c.drawRRect(RRect.fromRectAndRadius(rightTailRect, tailRadius), tailGlowPaint);

  // Taillight core
  final Paint tailCorePaint = Paint()..color = const Color(0xFFFF2D2D);
  c.drawRRect(RRect.fromRectAndRadius(leftTailRect, tailRadius), tailCorePaint);
  c.drawRRect(RRect.fromRectAndRadius(rightTailRect, tailRadius), tailCorePaint);

  // 8. License plate: small white rect in the center
  final double plateW = w * 0.20;
  final double plateH = bodyH * 0.26;
  final Rect plateRect = Rect.fromCenter(
    center: Offset(center.dx, bodyTop + bodyH * 0.62),
    width: plateW,
    height: plateH,
  );
  c.drawRect(plateRect, Paint()..color = const Color(0xFFFAFAFA));
  c.drawRect(
    plateRect,
    Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );

  // 9. Player: a thin spoiler line on top of the rear body
  if (player) {
    final Paint spoilerPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double spoilerY = bodyTop - 3.0;
    c.drawLine(
      Offset(center.dx - w * 0.46, spoilerY),
      Offset(center.dx + w * 0.46, spoilerY),
      spoilerPaint,
    );

    // Cyan active accent line across spoiler
    final Paint cyanTrim = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 1.2;
    c.drawLine(
      Offset(center.dx - w * 0.40, spoilerY),
      Offset(center.dx + w * 0.40, spoilerY),
      cyanTrim,
    );
  }
}
