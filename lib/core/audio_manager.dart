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

  // --- Engine state ---
  // There are no engine audio assets yet; these hooks only track state so a
  // looping engine sample can be plugged in later without touching callers.
  void startEngine() {}

  void updateEnginePitch(double speedRatio, bool flying) {
    _currentSpeedRatio = speedRatio.clamp(0.0, 1.5);
    _isFlying = flying;
  }

  double get engineSpeedRatio => _currentSpeedRatio;
  bool get engineFlying => _isFlying;

  void stopEngine() {}

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
    // Haptics always fire on a crash, but the sound respects the toggle.
    triggerHapticHeavy();
    if (!_isSoundEnabled) return;
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

  void dispose() {}
}

