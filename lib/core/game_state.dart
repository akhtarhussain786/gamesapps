import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'audio_manager.dart';

/// Semantic tone of a status chip or popup. Each tone maps to one colour.
enum ChipTone {
  info, // cyan
  caution, // amber
  danger, // red
  reward, // green
  stunt, // magenta
}

Color toneColor(ChipTone tone) {
  switch (tone) {
    case ChipTone.info:
      return GameConstants.neonCyan;
    case ChipTone.caution:
      return GameConstants.neonAmber;
    case ChipTone.danger:
      return GameConstants.neonRed;
    case ChipTone.reward:
      return GameConstants.neonGreen;
    case ChipTone.stunt:
      return GameConstants.playerMagenta;
  }
}

/// Chip priorities: a chip can only be replaced by one of equal or higher
/// priority (or by an update to itself) while it is still on screen.
class ChipPriority {
  static const int hint = 0;
  static const int info = 1;
  static const int landing = 2;
  static const int warning = 3;
}

class StatusChipInfo {
  /// Stable identity. Updating a chip with the same id changes its text in
  /// place instead of re-playing the enter animation every frame.
  final String id;
  String text;
  ChipTone tone;
  int priority;
  double durationSeconds;
  double elapsed = 0.0;

  StatusChipInfo({
    required this.id,
    required this.text,
    required this.tone,
    required this.priority,
    this.durationSeconds = 1.8,
  });

  bool get isExpired => elapsed >= durationSeconds;
}

/// Floating "+300 LANDING" style feedback, separate from warning chips so that
/// rewards are never overwritten by hazard alerts.
class ScorePopup {
  final int id;
  final String text;
  final ChipTone tone;
  final bool big;

  /// Player altitude when the popup spawned, so it rises from above the car.
  final double altitude;
  double age = 0.0;

  ScorePopup({required this.id, required this.text, required this.tone, this.big = false, this.altitude = 0.0});

  static const double lifetime = 1.2;
  bool get isExpired => age >= lifetime;
}

/// Core reactive state controller for ROADSTER RUSH.
class GameController extends ChangeNotifier {
  static final GameController instance = GameController._internal();
  GameController._internal();

  static const double levelDistanceWorld = 10000.0; // 500 m

  // Primary Gameplay Metrics
  int _score = 0;
  double _scoreAccumulator = 0.0;
  int _bestScore = 0;
  int _bestAtRunStart = 0;
  int _level = 1;
  double _distance = 0.0;
  double _levelDistance = 0.0;
  double _speed = 0.0;
  double _airMeter = GameConstants.airMeterMax;

  // Countdown: 3, 2, 1 (frozen) then GO! (already driving)
  double _countdownTimer = 3.99;
  bool get isCountdownActive => _countdownTimer > 0.0;
  String get countdownText {
    if (_countdownTimer > 2.0) return '3';
    if (_countdownTimer > 1.0) return '2';
    if (_countdownTimer > 0.0) return '1';
    if (_countdownTimer > -0.6) return 'GO!';
    return '';
  }

  // Touch To Drive
  bool _isJoystickTouching = false;
  bool _isFlyTouching = false;
  bool _isScreenTouching = false;
  bool get isTouchActive => _isJoystickTouching || _isFlyTouching || _isScreenTouching || _isFlying;

  // Flight & Stunts
  bool _isFlying = false;
  bool _isFlipping = false;
  double _flipAngle = 0.0;
  double _playerAltitude = 0.0;
  double _playerVy = 0.0;
  double _playerRoll = 0.0;
  double _peakAltitude = 0.0;
  int _stacksClearedThisFlight = 0;

  // Steering
  double _steerRaw = 0.0;
  double _steerSmoothed = 0.0;

  // Lifecycle
  bool _isPaused = false;
  bool _isGameOver = false;
  String _crashReason = '';

  // Feedback
  StatusChipInfo? _currentStatusChip;
  bool _isLandingSafe = true;
  bool _flyCue = false;
  final List<ScorePopup> _popups = [];
  int _popupSeq = 0;

  // Getters
  int get score => _score;
  int get bestScore => _bestScore;
  bool get isNewBest => _score > _bestAtRunStart && _score > 0;
  int get level => _level;
  double get distance => _distance;
  int get distanceMeters => (_distance * GameConstants.metresPerWorldUnit).toInt();
  double get levelProgress => (_levelDistance / levelDistanceWorld).clamp(0.0, 1.0);
  int get levelMetersRemaining =>
      ((levelDistanceWorld - _levelDistance) * GameConstants.metresPerWorldUnit).ceil().clamp(0, 99999);
  double get speed => _speed;

  /// Forward speed in km/h, consistent with the distance readout.
  int get speedKmh =>
      (_speed * GameConstants.worldUnitsPerSpeed * GameConstants.metresPerWorldUnit * 3.6).round();

  /// World units travelled per second.
  double get worldSpeed => _speed * GameConstants.worldUnitsPerSpeed;
  double get airMeter => _airMeter;
  bool get isFlying => _isFlying;
  bool get isFlipping => _isFlipping;
  double get flipAngle => _flipAngle;
  double get playerAltitude => _playerAltitude;
  double get playerVy => _playerVy;
  double get playerRoll => _playerRoll;
  double get steerSmoothed => _steerSmoothed;
  bool get isPaused => _isPaused;
  bool get isGameOver => _isGameOver;
  String get crashReason => _crashReason;
  StatusChipInfo? get currentStatusChip => _currentStatusChip;
  bool get isLandingSafe => _isLandingSafe;
  bool get flyCue => _flyCue;
  bool get isAirborne => _playerAltitude > GameConstants.airborneThreshold;
  List<ScorePopup> get popups => List.unmodifiable(_popups);

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
    _bestAtRunStart = _bestScore;
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
    _peakAltitude = 0.0;
    _stacksClearedThisFlight = 0;
    _steerRaw = 0.0;
    _steerSmoothed = 0.0;
    _isPaused = false;
    _isGameOver = false;
    _crashReason = '';
    _currentStatusChip = null;
    _isLandingSafe = true;
    _flyCue = false;
    _popups.clear();
    AudioManager.instance.startEngine();
    notifyListeners();
  }

  // --- Input Handlers (per-pointer tracking) ---
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

    // Releasing must ALWAYS stop the thrusters, even while paused; otherwise a
    // release during the pause menu leaves the car flying after resume.
    if (!held) {
      _isFlying = false;
      notifyListeners();
      return;
    }

    if (_isGameOver || _isPaused) return;
    if (isCountdownActive) {
      notifyListeners(); // Engages at "GO!" if still held (see update()).
      return;
    }

    if (_airMeter > 1.0) {
      if (!_isFlying) {
        AudioManager.instance.playWhoosh();
      }
      _isFlying = true;
    }
    notifyListeners();
  }

  bool triggerFlip() {
    if (_isGameOver || _isPaused || _isFlipping) return false;
    if (!isAirborne) {
      showStatusChip('flip', 'NEED AIR TO FLIP', ChipTone.caution, duration: 1.0, priority: ChipPriority.info);
      return false;
    }
    _isFlipping = true;
    _flipAngle = 0.0;
    AudioManager.instance.playFlipChime();
    return true;
  }

  void setFlyCue(bool cue) {
    _flyCue = cue;
  }

  // --- Status Chips ---
  void showStatusChip(
    String id,
    String text,
    ChipTone tone, {
    double duration = 1.8,
    int priority = ChipPriority.info,
  }) {
    final StatusChipInfo? current = _currentStatusChip;
    if (current != null && !current.isExpired) {
      if (current.id == id) {
        // Same chip: update in place, keep it alive.
        current
          ..text = text
          ..tone = tone
          ..priority = priority
          ..durationSeconds = duration
          ..elapsed = 0.0;
        notifyListeners();
        return;
      }
      if (current.priority > priority) return; // Don't bury a more important message.
    }
    _currentStatusChip = StatusChipInfo(
      id: id,
      text: text,
      tone: tone,
      priority: priority,
      durationSeconds: duration,
    );
    notifyListeners();
  }

  void clearStatusChip([String? id]) {
    if (_currentStatusChip != null && (id == null || _currentStatusChip!.id == id)) {
      _currentStatusChip = null;
      notifyListeners();
    }
  }

  // --- Popups ---
  void _addPopup(String text, ChipTone tone, {bool big = false}) {
    _popups.add(ScorePopup(id: _popupSeq++, text: text, tone: tone, big: big, altitude: _playerAltitude));
    if (_popups.length > 4) _popups.removeAt(0);
  }

  // --- Pause & Resume ---
  void pauseGame() {
    if (_isGameOver || _isPaused) return;
    _isPaused = true;
    AudioManager.instance.stopEngine();
    notifyListeners();
  }

  void resumeGame() {
    if (!_isPaused) return;
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
    _flyCue = false;
    _crashReason = reason;
    _currentStatusChip = null;
    AudioManager.instance.playCrash();
    AudioManager.instance.stopEngine();
    if (_score > _bestScore) {
      _bestScore = _score;
    }
    _saveBestScore();
    notifyListeners();
  }

  /// Called once per frame by the game with the number of pile cars the player
  /// just flew over.
  void triggerOverpassBonus(int carsCleared) {
    if (carsCleared <= 0) return;
    _stacksClearedThisFlight += carsCleared;
    final int pts = GameConstants.bonusOverpassStack * carsCleared;
    addScore(pts);
    _addPopup(carsCleared > 1 ? '+$pts  OVERPASS x$carsCleared' : '+$pts  OVERPASS', ChipTone.info);
  }

  /// Called by the game the frame the car touches back down safely.
  void handleTouchdown() {
    if (_isFlipping) {
      // Landed before finishing the rotation: no stunt points.
      _isFlipping = false;
      _flipAngle = 0.0;
      showStatusChip('flip', 'FLIP NOT FINISHED', ChipTone.caution, duration: 1.0, priority: ChipPriority.landing);
    }

    // Only a real jump over traffic earns the landing bonus. Tiny hops used to
    // pay +300 each, which was ~30x more than driving.
    if (_stacksClearedThisFlight > 0) {
      addScore(GameConstants.bonusPerfectLanding);
      AudioManager.instance.playLandingBonus();
      _addPopup('+${GameConstants.bonusPerfectLanding}  CLEAN LANDING', ChipTone.reward);
    }
    _stacksClearedThisFlight = 0;
    _peakAltitude = 0.0;
  }

  void setLandingSafety(bool safe) {
    if (_isLandingSafe != safe) {
      _isLandingSafe = safe;
    }
    if (isAirborne && !_isGameOver) {
      if (safe) {
        showStatusChip('landing', 'LANDING CLEAR', ChipTone.reward, duration: 0.5, priority: ChipPriority.landing);
      } else {
        showStatusChip('landing', 'HAZARD BELOW · HOLD FLY', ChipTone.danger, duration: 0.5, priority: ChipPriority.warning);
      }
    }
  }

  // --- Per-Frame Simulation Update ---
  void update(double rawDt) {
    if (_isPaused) return;

    final double dt = math.min(rawDt, GameConstants.maxDeltaTime);

    // Popups keep animating during the crash slow-mo.
    for (final p in _popups) {
      p.age += dt;
    }
    _popups.removeWhere((p) => p.isExpired);

    if (_isGameOver) {
      notifyListeners();
      return;
    }

    // 1. Countdown: frozen during 3-2-1; driving is allowed during "GO!".
    if (_countdownTimer > -0.6) {
      final bool wasCounting = _countdownTimer > 0.0;
      _countdownTimer -= dt;
      if (_countdownTimer > 0.0) {
        _speed = 0.0;
        notifyListeners();
        return;
      }
      // FLY held through the countdown takes effect the moment it ends.
      if (wasCounting && _isFlyTouching) {
        setFlyHeld(true);
      }
    }

    // 2. Speed & Touch-To-Drive
    final double maxSpeedForLevel = math.min(
      GameConstants.maxSpeedCap,
      GameConstants.startSpeed + 12.0 * (_level - 1),
    );

    if (isTouchActive) {
      if (_speed < GameConstants.startSpeed) {
        _speed = math.min(GameConstants.startSpeed, _speed + 35.0 * dt);
      } else if (_speed < maxSpeedForLevel) {
        _speed = math.min(maxSpeedForLevel, _speed + GameConstants.accelRate * dt);
      }
    } else {
      _speed = math.max(0.0, _speed - GameConstants.brakeRate * dt);
    }

    if (_speed <= 0.5 && !isTouchActive) {
      showStatusChip('drive', 'HOLD ANYWHERE TO DRIVE', ChipTone.caution, duration: 0.4, priority: ChipPriority.hint);
    }

    // Score & Distance only increase while moving
    if (_speed > 0.0) {
      final double distDelta = worldSpeed * dt;
      _distance += distDelta;
      _levelDistance += distDelta;
      _scoreAccumulator += distDelta * 0.02;
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
      _addPopup('LEVEL $_level  ·  SPEED UP', ChipTone.info, big: true);
    }

    // 3. Steering smoothing
    _steerSmoothed += (_steerRaw - _steerSmoothed) * math.min(1.0, 10.0 * dt);
    _playerRoll = _steerSmoothed * GameConstants.maxPlayerTiltRad;

    // 4. Flight physics: hold = lift, release = gravity
    if (_isFlying && _airMeter > 0.0) {
      _playerVy += GameConstants.flightLiftAccel * dt;
      _airMeter = math.max(0.0, _airMeter - GameConstants.airDrainRatePerSecond * dt);
      if (_airMeter <= 0.0) {
        _isFlying = false;
        showStatusChip('air', 'AIR DEPLETED', ChipTone.danger, duration: 1.2, priority: ChipPriority.warning);
      }
    } else {
      _playerVy -= GameConstants.flightGravity * dt;
      if (_playerAltitude <= 0.0) {
        _airMeter = math.min(GameConstants.airMeterMax, _airMeter + GameConstants.airRefillRatePerSecond * dt);
      }
    }

    _playerAltitude = (_playerAltitude + _playerVy * dt).clamp(0.0, GameConstants.maxFlightAltitude);
    if (_playerAltitude >= GameConstants.maxFlightAltitude) {
      _playerAltitude = GameConstants.maxFlightAltitude;
      _playerVy = math.min(0.0, _playerVy);
    } else if (_playerAltitude <= 0.0) {
      _playerAltitude = 0.0;
      _playerVy = 0.0;
    }
    _peakAltitude = math.max(_peakAltitude, _playerAltitude);

    // 5. Stunt flip: one full rotation in 0.6 s; points only when completed.
    if (_isFlipping) {
      _flipAngle += (2.0 * math.pi / GameConstants.flipDurationSeconds) * dt;
      if (_flipAngle >= 2.0 * math.pi) {
        _flipAngle = 0.0;
        _isFlipping = false;
        addScore(GameConstants.bonusStuntFlip);
        _addPopup('+${GameConstants.bonusStuntFlip}  FLIP', ChipTone.stunt);
      }
    }

    // Status chip expiry
    if (_currentStatusChip != null) {
      _currentStatusChip!.elapsed += dt;
      if (_currentStatusChip!.isExpired) {
        _currentStatusChip = null;
      }
    }

    AudioManager.instance.updateEnginePitch(_speed / GameConstants.startSpeed, _isFlying);

    notifyListeners();
  }
}
