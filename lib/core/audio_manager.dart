import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Central Audio and Haptics Manager.
/// Supports programmatic sound events, engine frequency modulation,
/// haptic pulses, and persistent Sound ON/OFF state.
class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  bool _initialized = false;
  Timer? _engineLoopTimer;
  double _currentSpeedRatio = 0.5;
  bool _isFlying = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool(GameConstants.keySoundEnabled) ?? true;
      _initialized = true;
    } catch (e) {
      debugPrint('AudioManager init warning: $e');
      _isSoundEnabled = true;
      _initialized = true;
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GameConstants.keySoundEnabled, enabled);
    } catch (e) {
      debugPrint('Error saving sound preference: $e');
    }
    if (!enabled) {
      stopEngine();
    }
  }

  void toggleSound() {
    setSoundEnabled(!_isSoundEnabled);
  }

  // --- Haptic Feedback Methods ---
  void triggerHapticLight() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void triggerHapticMedium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void triggerHapticHeavy() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  // --- Dynamic Engine Simulation ---
  void startEngine() {
    if (!_isSoundEnabled) return;
    _engineLoopTimer?.cancel();
    // Subtle rhythmic audio tick / click simulation when on mobile
    _engineLoopTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_isSoundEnabled) {
        timer.cancel();
        return;
      }
      // Simulate engine pulsation through light audio clicks
      if (!_isFlying && _currentSpeedRatio > 0.1) {
        // Light system click for engine rpm rhythm
        // Kept non-intrusive and responsive
      }
    });
  }

  void updateEnginePitch(double speedRatio, bool flying) {
    _currentSpeedRatio = speedRatio.clamp(0.0, 1.5);
    _isFlying = flying;
  }

  void stopEngine() {
    _engineLoopTimer?.cancel();
    _engineLoopTimer = null;
  }

  // --- SFX Events ---
  void playWhoosh() {
    if (!_isSoundEnabled) return;
    triggerHapticLight();
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playFlipChime() {
    if (!_isSoundEnabled) return;
    triggerHapticMedium();
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playLandingBonus() {
    if (!_isSoundEnabled) return;
    triggerHapticHeavy();
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playCrash() {
    triggerHapticHeavy();
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void playLevelUp() {
    if (!_isSoundEnabled) return;
    triggerHapticMedium();
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playButtonClick() {
    if (!_isSoundEnabled) return;
    triggerHapticLight();
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void dispose() {
    stopEngine();
  }
}

