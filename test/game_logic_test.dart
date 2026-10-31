import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadster_rush/core/constants.dart';
import 'package:roadster_rush/core/game_state.dart';
import 'package:roadster_rush/game/components/landing_target.dart';
import 'package:roadster_rush/game/components/road_mesh.dart';
import 'package:roadster_rush/game/components/traffic_cluster.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _dt = 1.0 / 60.0;

GameController _freshRun() {
  final c = GameController.instance;
  c.resetGame();
  return c;
}

/// Advance the simulation by [seconds] in fixed steps.
void _run(GameController c, double seconds) {
  for (double t = 0; t < seconds; t += _dt) {
    c.update(_dt);
  }
}

/// Skip the 3-2-1 countdown.
void _skipCountdown(GameController c) => _run(c, 4.1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('countdown & flight input', () {
    test('FLY cannot lift off during 3-2-1 but engages at GO if still held', () {
      final c = _freshRun();
      c.setFlyHeld(true);
      _run(c, 2.0);
      expect(c.isFlying, isFalse);
      expect(c.playerAltitude, 0.0);

      _run(c, 2.2); // countdown ends while still holding
      expect(c.isFlying, isTrue);
      expect(c.playerAltitude, greaterThan(0.0));
    });

    test('the car can drive during "GO!"', () {
      final c = _freshRun();
      c.setTouchActive(true);
      _run(c, 4.1);
      expect(c.countdownText, 'GO!');
      expect(c.speed, greaterThan(0.0));
    });

    test('releasing FLY while paused stops the thrusters', () {
      final c = _freshRun();
      _skipCountdown(c);
      c.setFlyHeld(true);
      _run(c, 0.3);
      expect(c.isFlying, isTrue);

      c.pauseGame();
      c.setFlyHeld(false);
      c.resumeGame();
      expect(c.isFlying, isFalse);
    });
  });

  group('bonuses', () {
    test('flip points are paid on completion, not on press', () {
      final c = _freshRun();
      _skipCountdown(c);
      c.setFlyHeld(true);
      _run(c, 0.6);
      final int before = c.score;

      expect(c.triggerFlip(), isTrue);
      _run(c, 0.1);
      expect(c.score - before, lessThan(GameConstants.bonusStuntFlip));

      _run(c, GameConstants.flipDurationSeconds);
      expect(c.isFlipping, isFalse);
      expect(c.score - before, greaterThanOrEqualTo(GameConstants.bonusStuntFlip));
    });

    test('landing mid-flip pays nothing for the flip', () {
      final c = _freshRun();
      _skipCountdown(c);
      c.setFlyHeld(true);
      _run(c, 0.4);
      c.setFlyHeld(false);
      c.triggerFlip();
      final int before = c.score;
      c.handleTouchdown();
      expect(c.isFlipping, isFalse);
      expect(c.score, before);
    });

    test('a hop without clearing a pile earns no landing bonus', () {
      final c = _freshRun();
      _skipCountdown(c);
      final int before = c.score;
      c.handleTouchdown();
      expect(c.score, before);
    });

    test('clearing a pile then landing earns overpass + landing bonus', () {
      final c = _freshRun();
      _skipCountdown(c);
      final int before = c.score;
      c.triggerOverpassBonus(2);
      c.handleTouchdown();
      expect(
        c.score - before,
        2 * GameConstants.bonusOverpassStack + GameConstants.bonusPerfectLanding,
      );
      expect(c.popups.length, 2);
    });

    test('equalling the best score is not a new best', () async {
      final c = _freshRun();
      _skipCountdown(c);
      c.addScore(500);
      c.triggerGameOver('test');
      // The controller is a singleton, so tie whatever the best is now.
      final int best = c.bestScore;
      c.resetGame();
      _skipCountdown(c);
      c.addScore(best);
      expect(c.isNewBest, isFalse);
      c.addScore(1);
      expect(c.isNewBest, isTrue);
    });
  });

  group('status chip', () {
    test('a hint cannot hide a warning', () {
      final c = _freshRun();
      c.showStatusChip('stack', 'FLY NOW!', ChipTone.danger, priority: ChipPriority.warning);
      c.showStatusChip('drive', 'HOLD ANYWHERE TO DRIVE', ChipTone.caution, priority: ChipPriority.hint);
      expect(c.currentStatusChip!.id, 'stack');
    });

    test('same id updates text in place', () {
      final c = _freshRun();
      c.showStatusChip('stack', 'PILE AHEAD 40M', ChipTone.caution);
      final first = c.currentStatusChip;
      c.showStatusChip('stack', 'PILE AHEAD 39M', ChipTone.caution);
      expect(identical(first, c.currentStatusChip), isTrue);
      expect(c.currentStatusChip!.text, 'PILE AHEAD 39M');
    });
  });

  group('traffic piles', () {
    test('every elevated car rests on another car', () {
      final t = TrafficManager()..reset();
      for (int level = 1; level <= 8; level++) {
        t.update(dt: _dt, camZ: level * 20000.0, level: level);
      }
      final cars = t.cars;
      expect(cars, isNotEmpty);
      for (final car in cars.where((c) => c.layer > 0)) {
        final bool supported = cars.any((o) =>
            o.layer == car.layer - 1 && o.wx == car.wx && o.wz == car.wz);
        expect(supported, isTrue, reason: 'floating car at layer ${car.layer}');
        expect(car.wy, car.layer * GameConstants.carStackHeight);
      }
    });

    test('hit box: same lane collides, adjacent lane and above the top do not', () {
      final t = TrafficManager()..reset();
      t.cars.add(TrafficCar(wx: 0, wy: 0, wz: 1000, layer: 0, bodyColor: GameConstants.trafficRed));
      expect(t.checkCollision(playerWx: 0, playerWy: 0, playerWz: 1000 - 50), isTrue);
      expect(t.checkCollision(playerWx: 600, playerWy: 0, playerWz: 1000 - 50), isFalse);
      expect(
        t.checkCollision(playerWx: 0, playerWy: GameConstants.carStackHeight + 1, playerWz: 1000 - 50),
        isFalse,
      );
      expect(t.collectOverpasses(playerWx: 0, playerWy: GameConstants.carStackHeight + 1, playerWz: 950), 1);
    });

    test('hazard lookup is measured from the player, not the camera', () {
      final t = TrafficManager()..reset();
      t.cars.add(TrafficCar(wx: 0, wy: 0, wz: 1000, layer: 0, bodyColor: GameConstants.trafficRed));
      // Car is between camera and player: already behind the player.
      expect(t.nextObstacleInPath(playerWx: 0, playerWz: 1500), isNull);
      final ahead = t.nextObstacleInPath(playerWx: 0, playerWz: 600);
      expect(ahead, isNotNull);
      expect(ahead!.distance, 400);
      // Other lane is ignored.
      expect(t.nextObstacleInPath(playerWx: 600, playerWz: 600), isNull);
    });
  });

  group('world / screen agreement', () {
    test('the road under the player projects onto the player ground line', () {
      const size = Size(390, 844);
      final pt = RoadMesh().project(
        wx: 0,
        wy: 0,
        wz: GameConstants.playerDepth,
        size: size,
        camX: 0,
        camH: GameConstants.cameraHeight,
        camZ: 0,
        camDepth: GameConstants.cameraDepth,
        horizonY: size.height * GameConstants.horizonYRatio,
      )!;
      expect(pt.y / size.height, closeTo(GameConstants.playerGroundYRatio, 1e-9));
    });

    test('landing prediction uses world speed and vertical velocity', () {
      final target = LandingTarget();
      final traffic = TrafficManager()..reset();
      const double h = 200.0, vy = 300.0, v = 1000.0, z0 = 5000.0;
      target.update(
        dt: _dt,
        playerWx: 0,
        playerWy: h,
        playerVy: vy,
        playerWz: z0,
        worldSpeed: v,
        trafficManager: traffic,
      );
      const double g = GameConstants.flightGravity;
      final double t = (vy + math.sqrt(vy * vy + 2 * g * h)) / g;
      expect(target.predictedLandingZ, closeTo(z0 + v * t, 1e-6));
      expect(target.isSafe, isTrue);

      traffic.cars.add(TrafficCar(
        wx: 0,
        wy: 0,
        wz: target.predictedLandingZ,
        layer: 0,
        bodyColor: GameConstants.trafficBlue,
      ));
      target.update(
        dt: _dt,
        playerWx: 0,
        playerWy: h,
        playerVy: vy,
        playerWz: z0,
        worldSpeed: v,
        trafficManager: traffic,
      );
      expect(target.isSafe, isFalse);
    });
  });
}
