import 'package:flutter/material.dart';

/// Renders the background sky gradient, atmospheric horizon fog band,
/// and two parallax layers of low-poly city buildings.
/// Ensures NO black gaps: the skyline bottom edge sits exactly on horizonY.
class SkylineHorizon {
  // Pre-configured building data for parallax layer 1 (Far) and layer 2 (Near)
  static const List<_BldgTemplate> _farBldgs = [
    _BldgTemplate(width: 70, height: 160, color: Color(0xFF222C3C), winCols: 2, winRows: 5),
    _BldgTemplate(width: 85, height: 210, color: Color(0xFF2A364A), winCols: 3, winRows: 7, hasAntenna: true),
    _BldgTemplate(width: 60, height: 130, color: Color(0xFF1E2634), winCols: 2, winRows: 4),
    _BldgTemplate(width: 90, height: 190, color: Color(0xFF323F54), winCols: 3, winRows: 6),
    _BldgTemplate(width: 75, height: 150, color: Color(0xFF242E3E), winCols: 2, winRows: 5),
    _BldgTemplate(width: 80, height: 220, color: Color(0xFF2D394C), winCols: 3, winRows: 8, hasAntenna: true),
    _BldgTemplate(width: 65, height: 140, color: Color(0xFF1F2837), winCols: 2, winRows: 4),
  ];

  static const List<_BldgTemplate> _nearBldgs = [
    _BldgTemplate(width: 95, height: 240, color: Color(0xFF2D3A4E), winCols: 3, winRows: 8),
    _BldgTemplate(width: 110, height: 310, color: Color(0xFF38475E), winCols: 4, winRows: 10, hasAntenna: true),
    _BldgTemplate(width: 85, height: 190, color: Color(0xFFD35400), winCols: 3, winRows: 6), // Warm orange low-poly accent
    _BldgTemplate(width: 100, height: 270, color: Color(0xFF2B374A), winCols: 3, winRows: 9),
    _BldgTemplate(width: 120, height: 330, color: Color(0xFF35445A), winCols: 4, winRows: 11, hasAntenna: true),
    _BldgTemplate(width: 90, height: 220, color: Color(0xFFE67E22), winCols: 3, winRows: 7), // Accent orange
    _BldgTemplate(width: 105, height: 280, color: Color(0xFF313F53), winCols: 3, winRows: 9),
  ];

  void update(double dt) {}

  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double horizonY,
  }) {
    // 1. Sky Gradient from Screen Top Down to horizonY
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 2.0);
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF161F2E), // Dusk slate
          Color(0xFF273549), // Twilight blue
          Color(0xFF475569), // Muted evening slate
          Color(0xFF7E92A6), // Soft dusk
          Color(0xFFB0BEC5), // Horizon fog blend
        ],
        stops: [0.0, 0.35, 0.65, 0.88, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 2. Parallax Skyline Layer 1 (Far Layer - Slow Parallax)
    _drawBuildingLayer(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      scrollOffset: camX * 0.04,
      templates: _farBldgs,
      opacity: 0.65,
    );

    // 3. Parallax Skyline Layer 2 (Near Layer - Medium Parallax)
    _drawBuildingLayer(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      scrollOffset: camX * 0.10,
      templates: _nearBldgs,
      opacity: 0.90,
    );

    // 4. Atmospheric Horizon Fog Band (Fades lower skyline into horizon)
    final Rect fogRect = Rect.fromLTWH(0, horizonY - 45.0, size.width, 48.0);
    final Paint fogPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x00B0BEC5),
          Color(0x88B0BEC5),
          Color(0xF0B0BEC5),
        ],
      ).createShader(fogRect);
    canvas.drawRect(fogRect, fogPaint);
  }

  void _drawBuildingLayer({
    required Canvas canvas,
    required Size size,
    required double horizonY,
    required double scrollOffset,
    required List<_BldgTemplate> templates,
    required double opacity,
  }) {
    final double totalPatternWidth = templates.fold(0.0, (sum, b) => sum + b.width + 6.0);
    if (totalPatternWidth <= 0) return;

    // Determine repeating start offset
    final double normalizedOffset = (scrollOffset % totalPatternWidth);
    double curX = -normalizedOffset - totalPatternWidth;

    final Paint bldgPaint = Paint();
    final Paint winPaint = Paint()..color = const Color(0x99FFF9D2);
    final Paint antPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 2.0;
    final Paint beaconPaint = Paint()..color = const Color(0xFFFF1744);

    while (curX < size.width + totalPatternWidth) {
      for (final b in templates) {
        final double bLeft = curX;
        final double bWidth = b.width;
        final double bHeight = b.height * (size.height / 850.0);
        final double bTop = horizonY - bHeight;

        // Draw building face if within visible horizontal window
        if (bLeft + bWidth > -50 && bLeft < size.width + 50) {
          bldgPaint.color = b.color.withValues(alpha: opacity);
          final Rect bRect = Rect.fromLTWH(bLeft, bTop, bWidth, bHeight);
          canvas.drawRect(bRect, bldgPaint);

          // Roof antenna & beacon
          if (b.hasAntenna) {
            final double antX = bLeft + bWidth * 0.5;
            canvas.drawLine(Offset(antX, bTop), Offset(antX, bTop - 18), antPaint);
            canvas.drawCircle(Offset(antX, bTop - 18), 2.5, beaconPaint);
          }

          // Illuminated voxel windows
          final double winW = (bWidth - 14) / b.winCols;
          const double winH = 4.0;
          final double rowSpacing = (bHeight - 24) / b.winRows;

          for (int r = 0; r < b.winRows; r++) {
            final double wy = bTop + 12 + r * rowSpacing;
            if (wy > horizonY - 10) break;

            for (int c = 0; c < b.winCols; c++) {
              if ((r * 3 + c) % 4 != 0) {
                final double wx = bLeft + 7 + c * winW;
                canvas.drawRect(Rect.fromLTWH(wx, wy, winW * 0.65, winH), winPaint);
              }
            }
          }
        }
        curX += bWidth + 6.0;
      }
    }
  }
}

class _BldgTemplate {
  final double width;
  final double height;
  final Color color;
  final int winCols;
  final int winRows;
  final bool hasAntenna;

  const _BldgTemplate({
    required this.width,
    required this.height,
    required this.color,
    required this.winCols,
    required this.winRows,
    this.hasAntenna = false,
  });
}
