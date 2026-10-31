import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import 'components/skyline_horizon.dart';
import 'components/road_mesh.dart';
import 'components/player_car.dart';
import 'components/traffic_cluster.dart';
import 'components/landing_target.dart';
import 'components/particles.dart';

/// Central Game Engine implementing OutRun-style pseudo-3D perspective:
/// Camera h = 1000, depth = 0.84, horizonY = size.height * 0.38.
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

  @override
  void update(double dt) {
    super.update(dt);

    // Issue 3: Pause pauses the update loop completely
    if (controller.isPaused) return;

    // Issue 1: Clamp dt to max 1/30 so lag spikes never cause jumps
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

    // Camera moves forward with distance
    _camZ = controller.distance;

    // Issue 3: Lateral speed = steerSmoothed * 900 * dt, clamp cam.x to [-roadHalfWidth+200, roadHalfWidth-200]
    _camX += controller.steerSmoothed * GameConstants.lateralSpeed * clampedDt;
    _camX = _camX.clamp(
      -GameConstants.roadHalfWidth + GameConstants.roadMargin,
      GameConstants.roadHalfWidth - GameConstants.roadMargin,
    );

    // Update Player Car (tilts max ±8° based on steering)
    _playerCar.update(
      dt: clampedDt,
      steerSmoothed: controller.steerSmoothed,
      isFlying: controller.isFlying,
    );

    // Update Road & Traffic
    _roadMesh.update(clampedDt);
    _trafficManager.update(
      dt: clampedDt,
      camZ: _camZ,
      level: controller.level,
    );

    // Update Landing Target (projected on road at predicted touchdown Z)
    _landingTarget.update(
      dt: clampedDt,
      playerWx: _camX,
      playerWy: controller.playerAltitude,
      camZ: _camZ,
      speed: controller.speed,
      trafficManager: _trafficManager,
    );
    controller.setLandingSafety(_landingTarget.isSafe);

    final double playerWz = _camZ + 750.0;
    final double playerWy = controller.playerAltitude;

    // Collision Detection
    if (!controller.isGameOver && !controller.isCountdownActive) {
      if (_trafficManager.checkCollision(
        playerWx: _camX,
        playerWy: playerWy,
        playerWz: playerWz,
      )) {
        triggerCrash("COLLIDED WITH VEHICLE PILE");
      } else if (_trafficManager.checkOverpass(
        playerWx: _camX,
        playerWy: playerWy,
        playerWz: playerWz,
      )) {
        controller.triggerOverpassBonus();
      }
    }

    // Landing Touchdown Detection
    final bool isAirborne = playerWy > 20.0;
    if (_wasAirborne && !isAirborne && !controller.isGameOver) {
      if (_landingTarget.isSafe) {
        controller.triggerLandingBonus();
        _shakeIntensity = 8.0;
      } else {
        triggerCrash("CRASHED ON HAZARD DURING LANDING");
      }
    }
    _wasAirborne = isAirborne;

    // Tactical Alert Chips
    if (!controller.isGameOver && !isAirborne && !controller.isCountdownActive) {
      final double? distToStack = _trafficManager.getDistanceToNextStack(_camZ);
      if (distToStack != null && distToStack < 1200.0) {
        final int distMeters = (distToStack * 0.05).toInt();
        if (distToStack < 450.0) {
          controller.showStatusChip("HOLD FLY", StatusDotColor.cyan, 0.6);
        } else {
          controller.showStatusChip("STACK AHEAD ${distMeters}M", StatusDotColor.yellow, 0.6);
        }
      }
    }

    // Update Particles
    _particles.update(clampedDt, size.toSize(), controller.isFlying);

    final double screenX = size.x * 0.5;
    final double carScreenY = (size.y * 0.70) - ((playerWy / GameConstants.maxFlightAltitude).clamp(0.0, 1.0) * size.y * 0.28);

    if (controller.isFlying) {
      _particles.emitThrusterSparks(screenX: screenX, screenY: carScreenY, count: 2);
    } else if (controller.speed > 5.0 && !controller.isGameOver) {
      _particles.emitTireSmoke(screenX: screenX, screenY: size.y * 0.70, steerInput: controller.steerSmoothed);
    }
  }

  void triggerCrash(String reason) {
    if (controller.isGameOver) return;
    controller.triggerGameOver(reason);
    _shakeIntensity = 24.0;
    _slowMoTimer = 0.85;

    final double screenX = size.x * 0.5;
    final double carScreenY = (size.y * 0.70) - ((controller.playerAltitude / GameConstants.maxFlightAltitude).clamp(0.0, 1.0) * size.y * 0.28);
    _particles.emitCrashExplosion(screenX: screenX, screenY: carScreenY);
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

    // 1. BACKGROUND (Sky gradient -> Horizon fog -> Parallax skyline)
    _skyline.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      horizonY: horizonY,
    );

    // 2. ROAD (Trapezoids Far to Near, curbs, grass, dashed lines, billboards)
    _roadMesh.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      currentDistance: controller.distance,
      currentLevel: controller.level,
    );

    // 3. LANDING TARGET RING (Projected on road at predicted landing Z)
    _landingTarget.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      playerWx: _camX,
      playerWy: controller.playerAltitude,
      roadMesh: _roadMesh,
    );

    // 4. TRAFFIC CARS (Straight rear-view, clean rows in lanes, drawCar)
    _trafficManager.render(
      canvas: canvas,
      size: screenSize,
      camX: _camX,
      camZ: _camZ,
      horizonY: horizonY,
      roadMesh: _roadMesh,
    );

    // 5. PLAYER CAR (Fixed bottom-center, rear-view, underglow, max ±8° tilt)
    _playerCar.render(
      canvas: canvas,
      size: screenSize,
      wy: controller.playerAltitude,
      flipAngle: controller.flipAngle,
      isFlying: controller.isFlying,
      isFlipping: controller.isFlipping,
    );

    // 6. PARTICLES
    _particles.render(canvas);

    // 7. COUNTDOWN OVERLAY (3-2-1-GO! before run starts)
    if (controller.isCountdownActive || controller.countdownText.isNotEmpty) {
      _drawCountdown(canvas, screenSize);
    }
  }

  void _drawCountdown(Canvas canvas, Size size) {
    final String text = controller.countdownText;
    if (text.isEmpty) return;

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: text == 'GO!' ? 72 : 84,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
        color: text == 'GO!' ? GameConstants.neonGreen : GameConstants.neonCyan,
        shadows: [
          Shadow(
            color: text == 'GO!' ? GameConstants.neonGreen : GameConstants.neonCyan,
            blurRadius: 28.0,
          ),
          const Shadow(
            color: Colors.white,
            blurRadius: 10.0,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset center = Offset(
      (size.width - textPainter.width) * 0.5,
      (size.height * 0.42) - (textPainter.height * 0.5),
    );

    // Dark translucent glow pill behind countdown
    final Rect pillRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.42),
      width: textPainter.width + 56.0,
      height: textPainter.height + 24.0,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(20.0)),
      Paint()..color = const Color(0xCC070E1A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(20.0)),
      Paint()
        ..color = (text == 'GO!' ? GameConstants.neonGreen : GameConstants.neonCyan).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    textPainter.paint(canvas, center);
  }
}
