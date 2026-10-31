import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/theme.dart';
import 'components/skyline_horizon.dart';
import 'components/road_mesh.dart';
import 'components/player_car.dart';
import 'components/traffic_cluster.dart';
import 'components/landing_target.dart';
import 'components/particles.dart';

/// Central game engine: OutRun-style pseudo-3D road, traffic piles, flight.
///
/// The player lives in the same world as everything else: its rear bumper is
/// [GameConstants.playerDepth] ahead of the camera, so the car is drawn exactly
/// where collisions, overpasses and the landing reticle are evaluated.
class RoadsterGame extends FlameGame {
  final GameController controller = GameController.instance;

  late final SkylineHorizon _skyline;
  late final RoadMesh _roadMesh;
  late final PlayerCar _playerCar;
  late final TrafficManager _trafficManager;
  late final LandingTarget _landingTarget;
  late final ParticleManager _particles;

  double _camX = 0.0;
  double _camZ = 0.0;

  double _shakeIntensity = 0.0;
  double _slowMoTimer = 0.0;
  final math.Random _random = math.Random();
  bool _wasAirborne = false;

  double get _playerWz => _camZ + GameConstants.playerDepth;

  @override
  Color backgroundColor() => GameConstants.bgDark;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _skyline = SkylineHorizon();
    _roadMesh = RoadMesh();
    _playerCar = PlayerCar();
    _trafficManager = TrafficManager();
    _landingTarget = LandingTarget();
    _particles = ParticleManager();

    resetGameWorld();
  }

  void resetGameWorld() {
    _camX = 0.0;
    _camZ = 0.0;
    _shakeIntensity = 0.0;
    _slowMoTimer = 0.0;
    _wasAirborne = false;

    _trafficManager.reset();
    _particles.reset();
  }

  /// Screen placement of the player for the current frame.
  PlayerPose _playerPose(Size screen) {
    final double horizonY = screen.height * GameConstants.horizonYRatio;
    const double depth = GameConstants.playerDepth;
    const double scale = GameConstants.cameraDepth / depth;
    final double altitude = controller.playerAltitude;
    final double groundY = horizonY + scale * GameConstants.cameraHeight * (screen.height * 0.5);
    final double carY = horizonY + scale * (GameConstants.cameraHeight - altitude) * (screen.height * 0.5);
    return PlayerPose(
      x: screen.width * 0.5,
      groundY: groundY,
      carY: carY,
      width: scale * GameConstants.playerCarWidth * (screen.width * 0.5),
      altitudeRatio: (altitude / GameConstants.maxFlightAltitude).clamp(0.0, 1.0),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (controller.isPaused) return;

    double clampedDt = math.min(dt, GameConstants.maxDeltaTime);

    // Slow-mo on crash
    if (_slowMoTimer > 0.0) {
      _slowMoTimer -= clampedDt;
      clampedDt *= 0.25;
    }

    controller.update(clampedDt);

    if (_shakeIntensity > 0.0) {
      _shakeIntensity = math.max(0.0, _shakeIntensity - clampedDt * 25.0);
    }

    _camZ = controller.distance;

    _camX += controller.steerSmoothed * GameConstants.lateralSpeed * clampedDt;
    _camX = _camX.clamp(
      -GameConstants.roadHalfWidth + GameConstants.roadMargin,
      GameConstants.roadHalfWidth - GameConstants.roadMargin,
    );

    _playerCar.update(
      dt: clampedDt,
      steerSmoothed: controller.steerSmoothed,
      isFlying: controller.isFlying,
    );

    _roadMesh.update(clampedDt);
    _trafficManager.update(
      dt: clampedDt,
      camZ: _camZ,
      level: controller.level,
    );

    final double playerWz = _playerWz;
    final double playerWy = controller.playerAltitude;

    _landingTarget.update(
      dt: clampedDt,
      playerWx: _camX,
      playerWy: playerWy,
      playerVy: controller.playerVy,
      playerWz: playerWz,
      worldSpeed: controller.worldSpeed,
      trafficManager: _trafficManager,
    );

    final bool running = !controller.isGameOver && !controller.isCountdownActive;

    if (running) {
      controller.setLandingSafety(_landingTarget.isSafe);

      if (_trafficManager.checkCollision(playerWx: _camX, playerWy: playerWy, playerWz: playerWz)) {
        triggerCrash(_wasAirborne || playerWy > 0.0 ? 'CLIPPED A PILE IN MID-AIR' : 'COLLIDED WITH VEHICLE PILE');
      } else {
        final int cleared = _trafficManager.collectOverpasses(playerWx: _camX, playerWy: playerWy, playerWz: playerWz);
        controller.triggerOverpassBonus(cleared);
      }
    }

    // Touchdown: a clean landing (a crash on landing is caught by the
    // collision test above, which uses the same hit box).
    final bool isAirborne = controller.isAirborne;
    if (_wasAirborne && !isAirborne && !controller.isGameOver) {
      controller.handleTouchdown();
      _shakeIntensity = 6.0;
    }
    _wasAirborne = isAirborne;

    if (running) {
      _updateHazardCues(playerWz, playerWy, isAirborne);
    } else {
      controller.setFlyCue(false);
    }

    // Particles
    final Size screen = size.toSize();
    final PlayerPose pose = _playerPose(screen);
    _particles.update(clampedDt, screen, controller.isFlying);

    if (!controller.isGameOver) {
      if (controller.isFlying) {
        _particles.emitThrusterSparks(left: pose.nozzleLeft, right: pose.nozzleRight, count: 2);
      } else if (controller.speed > 5.0 && !isAirborne) {
        _particles.emitTireSmoke(
          screenX: pose.x,
          groundY: pose.groundY,
          carWidth: pose.width,
          steerInput: controller.steerSmoothed,
        );
      }
    }
  }

  /// "PILE AHEAD" / "FLY NOW" based on time-to-impact in the player's lane.
  void _updateHazardCues(double playerWz, double playerWy, bool isAirborne) {
    final ObstacleAhead? next = _trafficManager.nextObstacleInPath(playerWx: _camX, playerWz: playerWz);
    final double v = math.max(controller.worldSpeed, 1.0);
    bool cue = false;

    if (next != null && next.distance > 0.0 && playerWy < next.clearance) {
      // Time until the pile enters the hit window in front of the car.
      final double t = math.max(0.0, next.distance - GameConstants.hitDepthAhead) / v;
      // Time to climb from the current altitude to the pile's top under full lift.
      final double climb = math.sqrt(2.0 * math.max(0.0, next.clearance - playerWy) / GameConstants.flightLiftAccel);

      if (t < climb + 0.45) {
        cue = true;
        controller.showStatusChip('stack', 'FLY NOW!', ChipTone.danger, duration: 0.3, priority: ChipPriority.warning);
      } else if (t < 2.4 && !isAirborne) {
        final int meters = (next.distance * GameConstants.metresPerWorldUnit).round();
        final int cars = (next.clearance / GameConstants.carStackHeight).round();
        controller.showStatusChip(
          'stack',
          cars > 1 ? 'PILE AHEAD  ${meters}M  ·  $cars HIGH' : 'PILE AHEAD  ${meters}M',
          ChipTone.caution,
          duration: 0.3,
          priority: ChipPriority.info,
        );
      }
    }
    controller.setFlyCue(cue);
  }

  void triggerCrash(String reason) {
    if (controller.isGameOver) return;
    controller.triggerGameOver(reason);
    _shakeIntensity = 24.0;
    _slowMoTimer = 0.85;

    final PlayerPose pose = _playerPose(size.toSize());
    _particles.emitCrashExplosion(screenX: pose.x, screenY: pose.carY - pose.height * 0.4);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Size screenSize = size.toSize();
    final double horizonY = screenSize.height * GameConstants.horizonYRatio;

    if (_shakeIntensity > 0.0) {
      final double sx = (_random.nextDouble() - 0.5) * _shakeIntensity;
      final double sy = (_random.nextDouble() - 0.5) * _shakeIntensity;
      canvas.translate(sx, sy);
    }

    // 1. Sky & skyline
    _skyline.render(canvas: canvas, size: screenSize, camX: _camX, horizonY: horizonY);

    // 2. Road
    _roadMesh.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      currentDistance: controller.distance,
      currentLevel: controller.level,
    );

    // 3. Landing reticle (on the road surface)
    _landingTarget.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      playerWx: _camX,
      roadMesh: _roadMesh,
    );

    // 4. Traffic further away than the player
    final double playerWz = _playerWz;
    _trafficManager.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      roadMesh: _roadMesh,
      minWz: playerWz,
    );

    // 5. Player
    _playerCar.render(
      canvas: canvas,
      pose: _playerPose(screenSize),
      flipAngle: controller.flipAngle,
      isFlipping: controller.isFlipping,
    );

    // 6. Traffic between the player and the camera (drawn over the player)
    _trafficManager.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      roadMesh: _roadMesh,
      maxWz: playerWz,
    );

    // 7. Particles
    _particles.render(canvas);

    // 8. Countdown
    if (controller.countdownText.isNotEmpty) {
      _drawCountdown(canvas, screenSize);
    }
  }

  void _drawCountdown(Canvas canvas, Size size) {
    final String text = controller.countdownText;
    if (text.isEmpty) return;
    final bool go = text == 'GO!';
    final Color color = go ? GameConstants.neonGreen : Colors.white;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: GameFonts.display,
          fontSize: go ? 76 : 96,
          fontStyle: FontStyle.italic,
          letterSpacing: 2.0,
          color: color,
          shadows: [
            Shadow(color: (go ? GameConstants.neonGreen : GameConstants.neonCyan).withValues(alpha: 0.8), blurRadius: 24.0),
            const Shadow(color: Color(0xAA000000), blurRadius: 4.0, offset: Offset(0, 4)),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final double cy = size.height * 0.44;
    textPainter.paint(canvas, Offset((size.width - textPainter.width) * 0.5, cy - textPainter.height * 0.5));

    if (!go) {
      final hint = TextPainter(
        text: const TextSpan(
          text: 'HOLD ANYWHERE TO DRIVE',
          style: TextStyle(
            fontFamily: GameFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: Color(0xE6FFFFFF),
            shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6.0)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hint.paint(canvas, Offset((size.width - hint.width) * 0.5, cy + textPainter.height * 0.5 + 8.0));
    }
  }
}
