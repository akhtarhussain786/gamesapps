import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'audio_manager.dart';

enum StatusDotColor {
  green,
  yellow,
  red,
  cyan,
}

class StatusChipInfo {
  final String text;
  final StatusDotColor dotColor;
  final double durationSeconds;
  double elapsed = 0.0;

  StatusChipInfo({
    required this.text,
    required this.dotColor,
    this.durationSeconds = 1.8,
  });

  bool get isExpired => elapsed >= durationSeconds;
}

/// Core reactive state controller for ROADSTER RUSH.
class GameController extends ChangeNotifier {
  static final GameController instance = GameController._internal();
  GameController._internal();

  static const double levelDistanceWorld = 10000.0; // 500m in world distance units

  // Primary Gameplay Metrics
  int _score = 0;
  double _scoreAccumulator = 0.0;
  int _bestScore = 0;
  int _level = 1;
  double _distance = 0.0;
  double _levelDistance = 0.0;
  double _speed = 0.0; // Initialized to 0 during countdown
  double _airMeter = GameConstants.airMeterMax;

  // Countdown State (Issue 1)
  double _countdownTimer = 3.99; // 3, 2, 1, GO!
  bool get isCountdownActive => _countdownTimer > 0.0;
  String get countdownText {
    if (_countdownTimer > 2.0) return '3';
    if (_countdownTimer > 1.0) return '2';
    if (_countdownTimer > 0.0) return '1';
    if (_countdownTimer > -0.6) return 'GO!';
    return '';
  }

  // Touch To Drive State (Issue 2)
  bool _isJoystickTouching = false;
  bool _isFlyTouching = false;
  bool _isScreenTouching = false;
  bool get isTouchActive => _isJoystickTouching || _isFlyTouching || _isScreenTouching || _isFlying;

  // Flight & Stunt Status (Issue 3)
  bool _isFlying = false;
  bool _isFlipping = false;
  double _flipAngle = 0.0;
  double _playerAltitude = 0.0; // 0 is ground, max 400
  double _playerVy = 0.0;       // Vertical velocity
  double _playerRoll = 0.0;

  // Steering & Joystick Input (Issue 3)
  double _steerRaw = 0.0;      // -1.0 to 1.0
  double _steerSmoothed = 0.0; // Eased steering

  // Game Lifecycle State
  bool _isPaused = false;
  bool _isGameOver = false;
  String _crashReason = '';

  // Dynamic Status Chip
  StatusChipInfo? _currentStatusChip;
  bool _isLandingSafe = true;

  // Getters
  int get score => _score;
  int get bestScore => _bestScore;
  int get level => _level;
  double get distance => _distance;
  int get distanceMeters => (_distance * 0.05).toInt();
  double get levelProgress => (_levelDistance / levelDistanceWorld).clamp(0.0, 1.0);
  double get speed => _speed;
  double get airMeter => _airMeter;
  bool get isFlying => _isFlying;
  bool get isFlipping => _isFlipping;
  double get flipAngle => _flipAngle;
  double get playerAltitude => _playerAltitude;
  double get playerRoll => _playerRoll;
  double get steerSmoothed => _steerSmoothed;
  bool get isPaused => _isPaused;
  bool get isGameOver => _isGameOver;
  String get crashReason => _crashReason;
  StatusChipInfo? get currentStatusChip => _currentStatusChip;
  bool get isLandingSafe => _isLandingSafe;

  // --- Initialization & Storage ---
  Future<void> loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt(GameConstants.keyBestScore) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading best score: $e');
    }
  }

  Future<void> _saveBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameConstants.keyBestScore, _bestScore);
    } catch (e) {
      debugPrint('Error saving best score: $e');
    }
  }

  // --- Reset / Start Game ---
  void resetGame() {
    _score = 0;
    _scoreAccumulator = 0.0;
    _level = 1;
    _distance = 0.0;
    _levelDistance = 0.0;
    _speed = 0.0;
    _airMeter = GameConstants.airMeterMax;
    _countdownTimer = 3.99;
    _isJoystickTouching = false;
    _isFlyTouching = false;
    _isScreenTouching = false;
    _isFlying = false;
    _isFlipping = false;
    _flipAngle = 0.0;
    _playerAltitude = 0.0;
    _playerVy = 0.0;
    _playerRoll = 0.0;
    _steerRaw = 0.0;
    _steerSmoothed = 0.0;
    _isPaused = false;
    _isGameOver = false;
    _crashReason = '';
    _currentStatusChip = null;
    _isLandingSafe = true;
    AudioManager.instance.startEngine();
    notifyListeners();
  }

  // --- Input Handlers (Per-pointer tracking) ---
  void setJoystickSteer(double steer, bool isTouching) {
    _steerRaw = steer.clamp(-1.0, 1.0);
    _isJoystickTouching = isTouching;
    notifyListeners();
  }

  void setTouchActive(bool active) {
    _isScreenTouching = active;
    notifyListeners();
  }

  void setFlyHeld(bool held) {
    _isFlyTouching = held;
    if (_isGameOver || _isPaused) return;

    if (held && _airMeter > 1.0) {
      if (!_isFlying) {
        AudioManager.instance.playWhoosh();
      }
      _isFlying = true;
    } else {
      _isFlying = false;
    }
    notifyListeners();
  }

  bool triggerFlip() {
    if (_isGameOver || _isPaused || _isFlipping) return false;
    if (_playerAltitude < 20.0) {
      showStatusChip("NEED AIR TO FLIP", StatusDotColor.yellow, 1.0);
      return false;
    }
    _isFlipping = true;
    _flipAngle = 0.0;
    AudioManager.instance.playFlipChime();
    showStatusChip("STUNT FLIP +${GameConstants.bonusStuntFlip}", StatusDotColor.yellow, 1.5);
    addScore(GameConstants.bonusStuntFlip);
    return true;
  }

  // --- Status Chips ---
  void showStatusChip(String text, StatusDotColor dotColor, [double duration = 1.8]) {
    _currentStatusChip = StatusChipInfo(
      text: text,
      dotColor: dotColor,
      durationSeconds: duration,
    );
    notifyListeners();
  }

  void clearStatusChip() {
    if (_currentStatusChip != null) {
      _currentStatusChip = null;
      notifyListeners();
    }
  }

  // --- Pause & Resume ---
  void pauseGame() {
    _isPaused = true;
    AudioManager.instance.stopEngine();
    notifyListeners();
  }

  void resumeGame() {
    _isPaused = false;
    AudioManager.instance.startEngine();
    notifyListeners();
  }

  // --- Game Lifecycle Events ---
  void addScore(int points) {
    _score += points;
    if (_score > _bestScore) {
      _bestScore = _score;
      _saveBestScore();
    }
    notifyListeners();
  }

  void triggerGameOver(String reason) {
    if (_isGameOver) return;
    _isGameOver = true;
    _isFlying = false;
    _crashReason = reason;
    AudioManager.instance.playCrash();
    AudioManager.instance.stopEngine();
    if (_score > _bestScore) {
      _bestScore = _score;
      _saveBestScore();
    }
    notifyListeners();
  }

  void triggerLandingBonus() {
    addScore(GameConstants.bonusPerfectLanding);
    AudioManager.instance.playLandingBonus();
    showStatusChip("LANDING BONUS +${GameConstants.bonusPerfectLanding}", StatusDotColor.green, 1.5);
  }

  void triggerOverpassBonus() {
    addScore(GameConstants.bonusOverpassStack);
    showStatusChip("OVERPASS +${GameConstants.bonusOverpassStack}", StatusDotColor.cyan, 1.2);
  }

  void setLandingSafety(bool safe) {
    if (_isLandingSafe != safe) {
      _isLandingSafe = safe;
      if (_playerAltitude > 20.0) {
        if (safe) {
          showStatusChip("LANDING GOOD", StatusDotColor.green, 1.0);
        } else {
          showStatusChip("HAZARD BELOW", StatusDotColor.red, 1.0);
        }
      }
    }
  }

  // --- Per-Frame Simulation Update ---
  void update(double rawDt) {
    // Issue 3: Pause pauses the update loop completely
    if (_isPaused || _isGameOver) return;

    // Issue 1: Clamp dt to max 1/30 so lag spikes never cause jumps
    final double dt = math.min(rawDt, GameConstants.maxDeltaTime);

    // 1. Countdown Logic (3-2-1 countdown before run starts)
    if (_countdownTimer > -0.6) {
      _countdownTimer -= dt;
      _speed = 0.0;
      notifyListeners();
      return;
    }

    // 2. Speed & Touch-To-Drive (Issue 1 & 2)
    final double maxSpeedForLevel = math.min(
      GameConstants.maxSpeedCap,
      GameConstants.startSpeed + 12.0 * (_level - 1),
    );

    if (isTouchActive) {
      // Touch accelerates smoothly
      if (_speed < GameConstants.startSpeed) {
        // Accelerate smoothly from 0 towards start speed
        _speed = math.min(GameConstants.startSpeed, _speed + 35.0 * dt);
      } else if (_speed < maxSpeedForLevel) {
        // Smooth ramp up: speed += accel * dt (accel = 6 units/s^2)
        _speed = math.min(maxSpeedForLevel, _speed + GameConstants.accelRate * dt);
      }
    } else {
      // No touch -> speed decays smoothly toward 0 (brake = 80 units/s^2)
      _speed = math.max(0.0, _speed - GameConstants.brakeRate * dt);
    }

    // Hint: show "HOLD TO DRIVE" when stopped
    if (_speed <= 0.5 && !isTouchActive) {
      showStatusChip("HOLD TO DRIVE", StatusDotColor.yellow, 0.4);
    }

    // Score & Distance ONLY increase while moving
    if (_speed > 0.0) {
      final double distDelta = _speed * dt * 25.0; // Scaled to road coordinate space
      _distance += distDelta;
      _levelDistance += distDelta;
      _scoreAccumulator += distDelta * 0.02; // Smooth scoring progression while driving
      if (_scoreAccumulator >= 1.0) {
        final int pts = _scoreAccumulator.toInt();
        _score += pts;
        _scoreAccumulator -= pts;
        if (_score > _bestScore) {
          _bestScore = _score;
        }
      }
    }

    // Level Check
    if (_levelDistance >= levelDistanceWorld) {
      _levelDistance -= levelDistanceWorld;
      _level++;
      AudioManager.instance.playLevelUp();
      showStatusChip("LEVEL $_level! SPEED BOOST", StatusDotColor.cyan, 2.0);
    }

    // 3. Steering Smoothing (Issue 3)
    // steerSmoothed += (steer - steerSmoothed) * min(1, 10*dt)
    _steerSmoothed += (_steerRaw - _steerSmoothed) * math.min(1.0, 10.0 * dt);
    _playerRoll = _steerSmoothed * GameConstants.maxPlayerTiltRad;

    // 4. Flight Physics (Issue 3)
    // FLY: hold = lift (vy += 900*dt, max height 400), release = gravity (vy -= 1400*dt)
    if (_isFlying && _airMeter > 0.0) {
      _playerVy += GameConstants.flightLiftAccel * dt;
      _airMeter = math.max(0.0, _airMeter - GameConstants.airDrainRatePerSecond * dt);
      if (_airMeter <= 0.0) {
        _isFlying = false; // Air depleted, flight stops
        showStatusChip("AIR DEPLETED", StatusDotColor.red, 1.2);
      }
    } else {
      _playerVy -= GameConstants.flightGravity * dt;
      if (_playerAltitude <= 0.0) {
        // Refills 15/s on the ground
        _airMeter = math.min(GameConstants.airMeterMax, _airMeter + GameConstants.airRefillRatePerSecond * dt);
      }
    }

    // Apply vertical velocity to altitude
    _playerAltitude = (_playerAltitude + _playerVy * dt).clamp(0.0, GameConstants.maxFlightAltitude);
    if (_playerAltitude >= GameConstants.maxFlightAltitude) {
      _playerAltitude = GameConstants.maxFlightAltitude;
      _playerVy = math.min(0.0, _playerVy);
    } else if (_playerAltitude <= 0.0) {
      _playerAltitude = 0.0;
      _playerVy = 0.0;
    }

    // 5. Stunt Flip (Issue 3: one rotation in 0.6s)
    if (_isFlipping) {
      _flipAngle += (2.0 * math.pi / GameConstants.flipDurationSeconds) * dt;
      if (_flipAngle >= 2.0 * math.pi) {
        _flipAngle = 0.0;
        _isFlipping = false;
      }
    }

    // Status Chip Expiry
    if (_currentStatusChip != null) {
      _currentStatusChip!.elapsed += dt;
      if (_currentStatusChip!.isExpired) {
        _currentStatusChip = null;
      }
    }

    // Engine Audio Pitch
    AudioManager.instance.updateEnginePitch(_speed / GameConstants.startSpeed, _isFlying);

    notifyListeners();
  }
}
