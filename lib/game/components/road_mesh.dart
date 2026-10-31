import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ProjectedPoint {
  final double x;
  final double y;
  final double scale;

  const ProjectedPoint(this.x, this.y, this.scale);
}

/// OutRun-style pseudo-3D road rendering with distance fog, tiered grandstands,
/// animated pixel crowd, and roadside low-poly city skyscrapers.
class RoadMesh {
  double _crowdTimer = 0.0;

  void update(double dt) {
    _crowdTimer += dt * 6.0;
  }

  /// Classic OutRun Projection Function
  ProjectedPoint? project({
    required double wx,
    required double wy,
    required double wz,
    required Size size,
    required double camX,
    required double camH,
    required double camZ,
    required double camDepth,
    required double horizonY,
  }) {
    final double dz = wz - camZ;
    if (dz <= 1.0) return null;

    final double scale = camDepth / dz;
    final double sx = size.width * 0.5 + scale * (wx - camX) * (size.width * 0.5);
    final double sy = horizonY + scale * (camH - wy) * (size.height * 0.5);

    return ProjectedPoint(sx, sy, scale);
  }

  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double camZ,
    required double horizonY,
    required double currentDistance,
    required int currentLevel,
  }) {
    const double camH = GameConstants.cameraHeight;     // 1000
    const double camDepth = GameConstants.cameraDepth;  // 0.84
    const double segLen = GameConstants.segmentLength;  // 200
    const int numSegments = GameConstants.drawSegments; // 85

    final int baseIdx = (camZ / segLen).floor();

    final Paint groundPaint = Paint()..isAntiAlias = false;
    final Paint curbPaint = Paint()..isAntiAlias = false;
    final Paint asphaltPaint = Paint()..isAntiAlias = false;
    final Paint lanePaint = Paint();

    const Color fogColor = GameConstants.horizonFogColor;

    // Draw from FAR to NEAR so closer geometry naturally occludes distant geometry
    for (int i = numSegments; i >= 1; i--) {
      final double z1 = (baseIdx + i - 1) * segLen;
      final double z2 = (baseIdx + i) * segLen;

      if (z1 <= camZ + 10.0) continue;

      // Project road edges (near slice z1)
      final p1RoadL = project(wx: -GameConstants.roadHalfWidth, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p1RoadR = project(wx: GameConstants.roadHalfWidth, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p1CurbL = project(wx: -GameConstants.roadHalfWidth - 160.0, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p1CurbR = project(wx: GameConstants.roadHalfWidth + 160.0, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);

      // Project road edges (far slice z2)
      final p2RoadL = project(wx: -GameConstants.roadHalfWidth, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p2RoadR = project(wx: GameConstants.roadHalfWidth, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p2CurbL = project(wx: -GameConstants.roadHalfWidth - 160.0, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final p2CurbR = project(wx: GameConstants.roadHalfWidth + 160.0, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);

      if (p1RoadL == null || p1RoadR == null || p2RoadL == null || p2RoadR == null) continue;
      if (p1CurbL == null || p1CurbR == null || p2CurbL == null || p2CurbR == null) continue;
      if (p1RoadL.y < horizonY) continue;

      final int segIdx = baseIdx + i - 1;
      final bool isAlt = ((segIdx ~/ 3) % 2 == 0);

      // Distance fog calculation (smooth quadratic falloff toward horizon)
      final double rawFog = ((i - 16) / (numSegments - 16)).clamp(0.0, 1.0);
      final double fogFactor = rawFog * rawFog;

      // 1. Ground base (Soft grass/earth underneath curbs and scenery)
      final Color grassBase = isAlt ? GameConstants.grassGreen : GameConstants.grassDarkerGreen;
      groundPaint.color = Color.lerp(grassBase, fogColor, fogFactor * 0.95)!;

      final Path leftGround = Path()
        ..moveTo(0, p2CurbL.y)
        ..lineTo(p2CurbL.x, p2CurbL.y)
        ..lineTo(p1CurbL.x, p1CurbL.y)
        ..lineTo(0, p1CurbL.y)
        ..close();
      canvas.drawPath(leftGround, groundPaint);

      final Path rightGround = Path()
        ..moveTo(p2CurbR.x, p2CurbR.y)
        ..lineTo(size.width, p2CurbR.y)
        ..lineTo(size.width, p1CurbR.y)
        ..lineTo(p1CurbR.x, p1CurbR.y)
        ..close();
      canvas.drawPath(rightGround, groundPaint);

      // 2. Red & White Striped Rumble Curbs (with fog blending)
      final Color curbBase = isAlt ? GameConstants.curbRed : GameConstants.curbWhite;
      curbPaint.color = Color.lerp(curbBase, fogColor, fogFactor * 0.90)!;

      final Path leftCurb = Path()
        ..moveTo(p2CurbL.x, p2CurbL.y)
        ..lineTo(p2RoadL.x, p2RoadL.y)
        ..lineTo(p1RoadL.x, p1RoadL.y)
        ..lineTo(p1CurbL.x, p1CurbL.y)
        ..close();
      canvas.drawPath(leftCurb, curbPaint);

      final Path rightCurb = Path()
        ..moveTo(p2RoadR.x, p2RoadR.y)
        ..lineTo(p2CurbR.x, p2CurbR.y)
        ..lineTo(p1CurbR.x, p1CurbR.y)
        ..lineTo(p1RoadR.x, p1RoadR.y)
        ..close();
      canvas.drawPath(rightCurb, curbPaint);

      // 3. Dark Asphalt Road Bed (Visibly narrows smoothly into horizon fog)
      final Color asphaltBase = isAlt ? GameConstants.asphaltDark : GameConstants.asphaltDarker;
      asphaltPaint.color = Color.lerp(asphaltBase, fogColor, fogFactor * 0.92)!;

      final Path roadBed = Path()
        ..moveTo(p2RoadL.x, p2RoadL.y)
        ..lineTo(p2RoadR.x, p2RoadR.y)
        ..lineTo(p1RoadR.x, p1RoadR.y)
        ..lineTo(p1RoadL.x, p1RoadL.y)
        ..close();
      canvas.drawPath(roadBed, asphaltPaint);

      // 4. Dashed White Lane Lines (3 lanes at x = -600, 0, 600 -> dividers at x = -300 and +300)
      if (segIdx % 4 < 2) {
        lanePaint.color = Colors.white.withValues(
          alpha: (1.0 - fogFactor * 0.88).clamp(0.0, 0.95),
        );
        _drawLaneDivider(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, z2, -300.0, lanePaint);
        _drawLaneDivider(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, z2, 300.0, lanePaint);
      }

      // 5. Roadside Low-Poly Skyscrapers (Billboards at x = ±2100..2800)
      if (i % 3 == 0 && p1RoadL.scale > 0.0006) {
        _drawRoadsideSkyscraper(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, -2100.0, fogFactor, isLeft: true, segIdx: segIdx);
        _drawRoadsideSkyscraper(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, 2100.0, fogFactor, isLeft: false, segIdx: segIdx);
      }

      // 6. Stadium Grandstands with Animated Crowds (Directly beside curbs at x = ±1260)
      if (p1RoadL.scale > 0.0007) {
        _drawSideGrandstand(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, -1260.0, fogFactor, isLeft: true);
        _drawSideGrandstand(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, 1260.0, fogFactor, isLeft: false);
      }

      // 7. Level Gantry / Finish Banner Check
      _checkAndDrawFinishGantry(canvas, size, camX, camH, camZ, camDepth, horizonY, z1, currentLevel, fogFactor);
    }

    // 8. Soft atmospheric horizon fog wash (blends road vanishing point seamlessly)
    _drawHorizonFogWash(canvas, size, horizonY);
  }

  void _drawLaneDivider(
    Canvas canvas,
    Size size,
    double camX,
    double camH,
    double camZ,
    double camDepth,
    double horizonY,
    double z1,
    double z2,
    double laneX,
    Paint paint,
  ) {
    const double lineHalfW = 16.0;
    final p1L = project(wx: laneX - lineHalfW, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
    final p1R = project(wx: laneX + lineHalfW, wy: 0, wz: z1, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
    final p2L = project(wx: laneX - lineHalfW, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
    final p2R = project(wx: laneX + lineHalfW, wy: 0, wz: z2, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);

    if (p1L == null || p1R == null || p2L == null || p2R == null) return;

    final Path dash = Path()
      ..moveTo(p2L.x, p2L.y)
      ..lineTo(p2R.x, p2R.y)
      ..lineTo(p1R.x, p1R.y)
      ..lineTo(p1L.x, p1L.y)
      ..close();
    canvas.drawPath(dash, paint);
  }

  void _drawSideGrandstand(
    Canvas canvas,
    Size size,
    double camX,
    double camH,
    double camZ,
    double camDepth,
    double horizonY,
    double wz,
    double wx,
    double fogFactor, {
    required bool isLeft,
  }) {
    final pt = project(wx: wx, wy: 0, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
    if (pt == null || pt.scale <= 0) return;

    final double standW = pt.scale * 620.0 * (size.width * 0.5);
    final double standH = pt.scale * 240.0 * (size.height * 0.5);
    if (standW < 3.0) return;

    final double left = isLeft ? (pt.x - standW) : pt.x;
    final double top = pt.y - standH;

    // Concrete Tiered Base (Dark slate grey with fog blend)
    const Color baseConcrete = Color(0xFF263238);
    final Color standColor = Color.lerp(baseConcrete, GameConstants.horizonFogColor, fogFactor * 0.88)!;
    final Paint standPaint = Paint()..color = standColor;
    canvas.drawRect(Rect.fromLTWH(left, top, standW, standH), standPaint);

    // Grandstand canopy / railing
    final Paint railPaint = Paint()
      ..color = Color.lerp(const Color(0xFF455A64), GameConstants.horizonFogColor, fogFactor)!
      ..strokeWidth = math.max(1.0, pt.scale * 12.0)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(left, top), Offset(left + standW, top), railPaint);

    // Colorful Cheering Pixel Crowd
    if (pt.scale > 0.0010 && fogFactor < 0.80) {
      const List<Color> shirtColors = [
        Color(0xFFE53935), // Red
        Color(0xFF1E88E5), // Blue
        Color(0xFFFDD835), // Yellow
        Color(0xFF43A047), // Green
        Color(0xFFE91E63), // Pink
        Color(0xFFFFFFFF), // White
        Color(0xFFFB8C00), // Orange
      ];

      final double dotSize = math.max(2.0, pt.scale * 140.0);
      final double crowdOpacity = (1.0 - fogFactor).clamp(0.0, 1.0);

      for (int row = 0; row < 3; row++) {
        final double ry = top + (row * (standH / 3.2)) + 3.0;
        for (int col = 0; col < 5; col++) {
          final double wave = math.sin(_crowdTimer + row * 1.5 + col * 0.9) * 2.2;
          final double rx = left + (col * (standW / 5.0)) + 3.0;
          final Color rawColor = shirtColors[(row * 5 + col + wz.toInt()) % shirtColors.length];
          final Color colColor = Color.lerp(rawColor, GameConstants.horizonFogColor, fogFactor * 0.75)!
              .withValues(alpha: crowdOpacity);

          final Paint cp = Paint()..color = colColor;
          canvas.drawRect(Rect.fromLTWH(rx, ry + wave, dotSize, dotSize * 1.2), cp);
        }
      }
    }
  }

  void _drawRoadsideSkyscraper(
    Canvas canvas,
    Size size,
    double camX,
    double camH,
    double camZ,
    double camDepth,
    double horizonY,
    double wz,
    double wx,
    double fogFactor, {
    required bool isLeft,
    required int segIdx,
  }) {
    final pt = project(wx: wx, wy: 0, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
    if (pt == null || pt.scale <= 0) return;

    final double bldgW = pt.scale * 800.0 * (size.width * 0.5);
    final double bldgH = pt.scale * 900.0 * (size.height * 0.5);
    if (bldgW < 4.0) return;

    final double left = isLeft ? (pt.x - bldgW) : pt.x;
    final double top = pt.y - bldgH;

    // Palette: Slate Blue, Warm Orange, Steel Navy
    const List<Color> bldgPalette = [
      Color(0xFF222C3C),
      Color(0xFFD35400), // Warm orange low-poly accent
      Color(0xFF2E3D52),
      Color(0xFF1E2837),
      Color(0xFFE67E22), // Vibrant accent
    ];
    final Color rawColor = bldgPalette[(segIdx ~/ 3) % bldgPalette.length];
    final Color bldgColor = Color.lerp(rawColor, GameConstants.horizonFogColor, fogFactor * 0.85)!;

    // Main building tower
    final Paint bldgPaint = Paint()..color = bldgColor;
    canvas.drawRect(Rect.fromLTWH(left, top, bldgW, bldgH), bldgPaint);

    // Roof antenna & beacon
    if (pt.scale > 0.0012) {
      final double antX = left + bldgW * 0.5;
      final Paint antPaint = Paint()
        ..color = Color.lerp(const Color(0xFF64748B), GameConstants.horizonFogColor, fogFactor)!
        ..strokeWidth = math.max(1.0, pt.scale * 20.0);
      canvas.drawLine(Offset(antX, top), Offset(antX, top - pt.scale * 160.0), antPaint);

      final Paint beaconPaint = Paint()..color = const Color(0xFFFF1744).withValues(alpha: (1.0 - fogFactor).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(antX, top - pt.scale * 160.0), math.max(1.5, pt.scale * 25.0), beaconPaint);

      // Subtle illuminated voxel window strips
      if (fogFactor < 0.65) {
        final Paint winPaint = Paint()..color = const Color(0xD9FFF9D2).withValues(alpha: (0.8 - fogFactor * 0.8).clamp(0.0, 0.8));
        const int cols = 3;
        final int rows = math.min(8, math.max(3, (bldgH / 22.0).toInt()));
        final double winW = (bldgW - 12) / cols;
        final double winH = math.max(2.0, pt.scale * 30.0);

        for (int r = 0; r < rows; r++) {
          final double wy = top + 10.0 + r * (bldgH / rows);
          if (wy > pt.y - 15) break;
          for (int c = 0; c < cols; c++) {
            if ((r * 2 + c + segIdx) % 3 != 0) {
              final double wxPos = left + 6.0 + c * winW;
              canvas.drawRect(Rect.fromLTWH(wxPos, wy, winW * 0.65, winH), winPaint);
            }
          }
        }
      }
    }
  }

  void _checkAndDrawFinishGantry(
    Canvas canvas,
    Size size,
    double camX,
    double camH,
    double camZ,
    double camDepth,
    double horizonY,
    double wz,
    int currentLevel,
    double fogFactor,
  ) {
    const double finishInterval = 10000.0;
    final double nextFinishZ = currentLevel * finishInterval;
    final double distDiff = (wz - nextFinishZ).abs();

    if (distDiff < GameConstants.segmentLength * 0.85) {
      final pL = project(wx: -GameConstants.roadHalfWidth - 100, wy: 0, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final pR = project(wx: GameConstants.roadHalfWidth + 100, wy: 0, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final pTopL = project(wx: -GameConstants.roadHalfWidth - 100, wy: 650, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);
      final pTopR = project(wx: GameConstants.roadHalfWidth + 100, wy: 650, wz: wz, size: size, camX: camX, camH: camH, camZ: camZ, camDepth: camDepth, horizonY: horizonY);

      if (pL == null || pR == null || pTopL == null || pTopR == null) return;

      final Color steelColor = Color.lerp(const Color(0xFF475569), GameConstants.horizonFogColor, fogFactor * 0.85)!;
      final Paint metalPaint = Paint()
        ..color = steelColor
        ..strokeWidth = math.max(2.0, pL.scale * 30.0)
        ..style = PaintingStyle.stroke;

      // Steel pillars & crossbar
      canvas.drawLine(Offset(pL.x, pL.y), Offset(pTopL.x, pTopL.y), metalPaint);
      canvas.drawLine(Offset(pR.x, pR.y), Offset(pTopR.x, pTopR.y), metalPaint);
      canvas.drawLine(Offset(pTopL.x, pTopL.y), Offset(pTopR.x, pTopR.y), metalPaint);

      // Overhead Level Complete Banner
      final bannerH = pL.scale * 140.0 * (size.height * 0.5);
      final bannerRect = Rect.fromLTRB(pTopL.x, pTopL.y, pTopR.x, pTopL.y + bannerH);
      canvas.drawRect(bannerRect, Paint()..color = const Color(0xEE09142A));
      canvas.drawRect(
        bannerRect,
        Paint()
          ..color = GameConstants.neonCyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, pL.scale * 18.0),
      );

      // Stadium Lights
      final Paint lightPaint = Paint()..color = GameConstants.neonGreen;
      final double r = math.max(2.5, pL.scale * 28.0);
      for (double lx = bannerRect.left + 14; lx <= bannerRect.right - 14; lx += (bannerRect.width / 5)) {
        canvas.drawCircle(Offset(lx, bannerRect.center.dy), r, lightPaint);
      }
    }
  }

  void _drawHorizonFogWash(Canvas canvas, Size size, double horizonY) {
    // Soft atmospheric mist blending road into the sky gradient
    final Rect fogRect = Rect.fromLTWH(0, horizonY - 18.0, size.width, 36.0);
    final Paint fogPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GameConstants.horizonFogColor.withValues(alpha: 0.0),
          GameConstants.horizonFogColor.withValues(alpha: 0.70),
          GameConstants.horizonFogColor.withValues(alpha: 0.95),
          GameConstants.horizonFogColor.withValues(alpha: 0.20),
          GameConstants.horizonFogColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 0.50, 0.75, 1.0],
      ).createShader(fogRect);
    canvas.drawRect(fogRect, fogPaint);
  }
}
