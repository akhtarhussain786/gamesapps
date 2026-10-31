import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'road_mesh.dart';
import 'car_renderer.dart';

class TrafficCar {
  double wx = 0.0; // Lane centre: -600, 0 or 600
  double wy = 0.0; // Bottom of this car (layer * carStackHeight)
  double wz = 0.0; // Rear bumper distance along the road
  int layer = 0;
  Color bodyColor = GameConstants.trafficWhite;
  bool passedOver = false;

  TrafficCar({
    required this.wx,
    required this.wy,
    required this.wz,
    required this.layer,
    required this.bodyColor,
  });

  double get top => wy + GameConstants.carStackHeight;
}

/// The closest pile in the player's path.
class ObstacleAhead {
  /// World units from the player's rear bumper to the pile's rear bumper.
  final double distance;

  /// Altitude the car must be above to clear the pile.
  final double clearance;

  const ObstacleAhead(this.distance, this.clearance);
}

/// Spawns, tests and draws piles of abandoned cars.
/// Every elevated car sits on top of another car in the same slot.
class TrafficManager {
  final List<TrafficCar> _cars = [];
  final math.Random _random = math.Random();
  double _lastSpawnZ = 0.0;

  /// The first pile appears this far down the road, giving a new run ~3 s to
  /// get up to speed before anything needs dodging.
  static const double firstSpawnZ = 3500.0;

  List<TrafficCar> get cars => _cars;

  void reset() {
    _cars.clear();
    _lastSpawnZ = firstSpawnZ;
  }

  void update({
    required double dt,
    required double camZ,
    required int level,
  }) {
    _cars.removeWhere((car) => car.wz < camZ - 200.0);

    final double maxSpawnAhead = camZ + (GameConstants.drawSegments * GameConstants.segmentLength) - 400.0;
    final double spawnGap = math.max(1400.0, 2400.0 - (level * 180.0));

    while (_lastSpawnZ < maxSpawnAhead) {
      _spawnCluster(_lastSpawnZ, level);
      _lastSpawnZ += spawnGap + _random.nextDouble() * 600.0;
    }
  }

  void _spawnCluster(double baseZ, int level) {
    // Block one lane, or two at most, so there is always an open lane.
    final List<double> lanes = List.of(GameConstants.lanes)..shuffle(_random);
    final int laneCount = _random.nextDouble() > 0.35 ? 2 : 1;
    final int rows = 1 + _random.nextInt(level >= 3 ? 3 : 2);
    final int maxLayers = level >= 4 ? 3 : 2;
    const List<Color> colors = GameConstants.trafficColors;

    for (int row = 0; row < rows; row++) {
      for (int l = 0; l < laneCount; l++) {
        final double wz = baseZ + row * 220.0;
        final int height = 1 + (_random.nextDouble() < 0.45 ? _random.nextInt(maxLayers) : 0);
        for (int layer = 0; layer < height; layer++) {
          _cars.add(TrafficCar(
            wx: lanes[l],
            wy: layer * GameConstants.carStackHeight,
            wz: wz,
            layer: layer,
            bodyColor: colors[_random.nextInt(colors.length)],
          ));
        }
      }
    }
  }

  bool _inDepthWindow(double rel) =>
      rel >= GameConstants.hitDepthBehind && rel <= GameConstants.hitDepthAhead;

  /// True if any car body overlaps the player's car.
  bool checkCollision({
    required double playerWx,
    required double playerWy,
    required double playerWz,
  }) {
    for (final car in _cars) {
      if (!_inDepthWindow(car.wz - playerWz)) continue;
      if ((car.wx - playerWx).abs() >= GameConstants.hitHalfWidth) continue;
      if (playerWy >= car.top) continue; // Flying above this car
      if (playerWy + GameConstants.carStackHeight <= car.wy) continue; // Under an overhang (never in practice)
      return true;
    }
    return false;
  }

  /// Marks and counts cars the player is passing over this frame.
  int collectOverpasses({
    required double playerWx,
    required double playerWy,
    required double playerWz,
  }) {
    int count = 0;
    for (final car in _cars) {
      if (car.passedOver) continue;
      if (!_inDepthWindow(car.wz - playerWz)) continue;
      if ((car.wx - playerWx).abs() >= GameConstants.hitHalfWidth) continue;
      if (playerWy >= car.top) {
        car.passedOver = true;
        count++;
      }
    }
    return count;
  }

  /// Would the car hit something if it touched down at [landingZ]?
  bool isLandingBlocked({required double playerWx, required double landingZ}) {
    for (final car in _cars) {
      if (!_inDepthWindow(car.wz - landingZ)) continue;
      if ((car.wx - playerWx).abs() < GameConstants.hitHalfWidth) return true;
    }
    return false;
  }

  /// Nearest pile in the player's lane, ahead of the player (not the camera).
  ObstacleAhead? nextObstacleInPath({required double playerWx, required double playerWz}) {
    const double laneSlack = 120.0;
    double? best;
    double clearance = 0.0;
    for (final car in _cars) {
      final double rel = car.wz - playerWz;
      if (rel < GameConstants.hitDepthBehind) continue;
      if ((car.wx - playerWx).abs() >= GameConstants.hitHalfWidth + laneSlack) continue;
      if (best == null || rel < best - 1.0) {
        best = rel;
        clearance = car.top;
      } else if ((rel - best).abs() <= 1.0) {
        clearance = math.max(clearance, car.top);
      }
    }
    return best == null ? null : ObstacleAhead(best, clearance);
  }

  /// Draws cars in [minWz, maxWz) from far to near (bottom layer first).
  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double camZ,
    required double horizonY,
    required RoadMesh roadMesh,
    double minWz = double.negativeInfinity,
    double maxWz = double.infinity,
  }) {
    const double camH = GameConstants.cameraHeight;
    const double camDepth = GameConstants.cameraDepth;
    const double maxDist = GameConstants.drawSegments * GameConstants.segmentLength;

    final visible = _cars.where((c) {
      final double dz = c.wz - camZ;
      return dz > 10.0 && dz < maxDist && c.wz >= minWz && c.wz < maxWz;
    }).toList()
      ..sort((a, b) {
        final int byDepth = b.wz.compareTo(a.wz);
        return byDepth != 0 ? byDepth : a.layer.compareTo(b.layer);
      });

    for (final car in visible) {
      final pt = roadMesh.project(
        wx: car.wx,
        wy: car.wy,
        wz: car.wz,
        size: size,
        camX: camX,
        camH: camH,
        camZ: camZ,
        camDepth: camDepth,
        horizonY: horizonY,
      );
      if (pt == null || pt.scale <= 0) continue;

      final double w = pt.scale * GameConstants.trafficCarWidth * (size.width * 0.5);
      if (w < 2.5) continue;

      final double dz = car.wz - camZ;
      final double fog = ((dz - 3500.0) / (maxDist - 3500.0)).clamp(0.0, 1.0);
      final Color color = Color.lerp(car.bodyColor, GameConstants.horizonFogColor, fog * 0.85)!;

      drawTrafficCar(canvas, Offset(pt.x, pt.y), w, color, drawShadow: car.layer == 0);
    }
  }
}
