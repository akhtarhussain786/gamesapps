import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'road_mesh.dart';
import 'car_renderer.dart';

class TrafficCar {
  double wx = 0.0; // Lane x: strictly -600, 0, or 600
  double wy = 0.0; // Clean stack: wy += 60 per layer
  double wz = 0.0; // World distance along road
  Color bodyColor = GameConstants.trafficWhite;
  bool passedOver = false;

  TrafficCar({
    required this.wx,
    required this.wy,
    required this.wz,
    required this.bodyColor,
  });
}

/// Manages traffic vehicle clusters and stacks.
/// Vehicles are strictly rendered REAR-VIEW only using drawCar (never rotate, no random angles).
class TrafficManager {
  final List<TrafficCar> _cars = [];
  final math.Random _random = math.Random();
  double _lastSpawnZ = 1200.0;

  List<TrafficCar> get cars => _cars;

  void reset() {
    _cars.clear();
    _lastSpawnZ = 1200.0;
  }

  void update({
    required double dt,
    required double camZ,
    required int level,
  }) {
    // Remove cars that are far behind camera
    _cars.removeWhere((car) => car.wz < camZ - 200.0);

    // Spawn new clusters ahead in clean rows
    final double maxSpawnAhead = camZ + (GameConstants.drawSegments * GameConstants.segmentLength) - 400.0;
    final double spawnGap = math.max(1400.0, 2400.0 - (level * 180.0));

    while (_lastSpawnZ < maxSpawnAhead) {
      _spawnCluster(_lastSpawnZ, level);
      _lastSpawnZ += spawnGap + _random.nextDouble() * 600.0;
    }
  }

  void _spawnCluster(double baseZ, int level) {
    // Clusters = 3 to 6 cars at consecutive Z
    final int carCount = 3 + _random.nextInt(4);

    // Pick 1 or 2 lanes to obstruct in clean rows
    final List<double> chosenLanes = [];
    final List<double> availableLanes = List.from(GameConstants.lanes)..shuffle(_random);
    chosenLanes.add(availableLanes[0]);
    if (_random.nextDouble() > 0.35) {
      chosenLanes.add(availableLanes[1]);
    }

    const List<Color> colors = GameConstants.trafficColors;

    for (int i = 0; i < carCount; i++) {
      final double laneX = chosenLanes[i % chosenLanes.length];
      final double zOffset = (i ~/ chosenLanes.length) * 220.0;
      final double wz = baseZ + zOffset;

      // Piles stacked in world-y: wy += 60 per layer
      double wy = 0.0;
      if (i >= 2 && _random.nextDouble() > 0.45) {
        wy = (i % 2 == 0) ? GameConstants.carStackHeight : GameConstants.carStackHeight * 2.0;
      }

      _cars.add(TrafficCar(
        wx: laneX,
        wy: wy,
        wz: wz,
        bodyColor: colors[_random.nextInt(colors.length)],
      ));
    }
  }

  double? getDistanceToNextStack(double camZ) {
    double? minDist;
    for (final c in _cars) {
      if (c.wz > camZ) {
        final double d = c.wz - camZ;
        if (minDist == null || d < minDist) {
          minDist = d;
        }
      }
    }
    return minDist;
  }

  bool checkCollision({
    required double playerWx,
    required double playerWy,
    required double playerWz,
  }) {
    for (final car in _cars) {
      final double dz = (car.wz - playerWz).abs();
      if (dz < 160.0) {
        final double dx = (car.wx - playerWx).abs();
        if (dx < 260.0) {
          if (playerWy >= car.wy + GameConstants.carStackHeight) {
            continue; // Overpass safety
          }
          return true; // Crash
        }
      }
    }
    return false;
  }

  bool checkOverpass({
    required double playerWx,
    required double playerWy,
    required double playerWz,
  }) {
    for (final car in _cars) {
      if (!car.passedOver && playerWy >= car.wy + GameConstants.carStackHeight) {
        final double dz = (car.wz - playerWz).abs();
        final double dx = (car.wx - playerWx).abs();
        if (dz < 140.0 && dx < 280.0) {
          car.passedOver = true;
          return true;
        }
      }
    }
    return false;
  }

  void render({
    required Canvas canvas,
    required Size size,
    required double camX,
    required double camZ,
    required double horizonY,
    required RoadMesh roadMesh,
  }) {
    const double camH = GameConstants.cameraHeight;
    const double camDepth = GameConstants.cameraDepth;

    // Filter visible cars and sort FAR to NEAR
    final visible = _cars.where((c) {
      final double dz = c.wz - camZ;
      return dz > 10.0 && dz < (GameConstants.drawSegments * GameConstants.segmentLength);
    }).toList()
      ..sort((a, b) => b.wz.compareTo(a.wz));

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

      // Width = scale * 360 * size.width / 2
      final double w = pt.scale * 360.0 * (size.width * 0.5);
      if (w < 2.5) continue;

      // Distance fog blend for traffic car body
      final double dz = car.wz - camZ;
      const double maxDist = GameConstants.drawSegments * GameConstants.segmentLength;
      final double rawFog = ((dz - 3500.0) / (maxDist - 3500.0)).clamp(0.0, 1.0);
      final Color blendedColor = Color.lerp(car.bodyColor, GameConstants.horizonFogColor, rawFog * 0.85)!;

      // Draw car using unified drawCar (rear-view, straight, no random rotation)
      drawCar(
        canvas,
        Offset(pt.x, pt.y),
        w,
        blendedColor,
        player: false,
      );
    }
  }
}
