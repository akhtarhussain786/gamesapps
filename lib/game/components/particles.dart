import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum ParticleType {
  speedLine,
  tireSmoke,
  plasmaSpark,
  explosionDebris,
}

class PooledParticle {
  bool active = false;
  ParticleType type = ParticleType.plasmaSpark;
  double x = 0.0;
  double y = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  double size = 1.0;
  double life = 0.0;
  double maxLife = 1.0;
  Color color = Colors.white;

  void reset() {
    active = false;
    x = 0.0;
    y = 0.0;
    vx = 0.0;
    vy = 0.0;
    size = 1.0;
    life = 0.0;
    maxLife = 1.0;
  }
}

/// Object-pooled particle manager for 60fps rendering.
class ParticleManager {
  static const int maxParticles = 220;
  final List<PooledParticle> _pool = List.generate(maxParticles, (_) => PooledParticle());
  final math.Random _random = math.Random();

  void reset() {
    for (final p in _pool) {
      p.reset();
    }
  }

  PooledParticle? _getFreeParticle() {
    for (int i = 0; i < maxParticles; i++) {
      if (!_pool[i].active) return _pool[i];
    }
    return null;
  }

  void emitThrusterSparks({required Offset left, required Offset right, required int count}) {
    for (int i = 0; i < count; i++) {
      final p = _getFreeParticle();
      if (p == null) break;

      final Offset origin = _random.nextBool() ? left : right;
      p.active = true;
      p.type = ParticleType.plasmaSpark;
      p.x = origin.dx + (_random.nextDouble() * 8.0 - 4.0);
      p.y = origin.dy + 4.0;
      p.vx = (_random.nextDouble() - 0.5) * 80.0;
      p.vy = 140.0 + _random.nextDouble() * 220.0;
      p.size = 1.5 + _random.nextDouble() * 3.0;
      p.maxLife = 0.22 + _random.nextDouble() * 0.25;
      p.life = p.maxLife;
      p.color = _random.nextBool() ? GameConstants.neonCyan : Colors.white;
    }
  }

  void emitTireSmoke({
    required double screenX,
    required double groundY,
    required double carWidth,
    required double steerInput,
  }) {
    // Drift smoke only while actually turning.
    if (steerInput.abs() < 0.25 || _random.nextDouble() > 0.6) return;

    final p = _getFreeParticle();
    if (p == null) return;

    p.active = true;
    p.type = ParticleType.tireSmoke;
    // Smoke comes off the outside rear tyre of the turn.
    final double wheelOffset = (steerInput > 0 ? -0.42 : 0.42) * carWidth;
    p.x = screenX + wheelOffset + (_random.nextDouble() * 10.0 - 5.0);
    p.y = groundY - 4.0;
    p.vx = -steerInput * 45.0 + (_random.nextDouble() * 30.0 - 15.0);
    p.vy = 20.0 + _random.nextDouble() * 30.0;
    p.size = carWidth * (0.05 + _random.nextDouble() * 0.06);
    p.maxLife = 0.35 + _random.nextDouble() * 0.25;
    p.life = p.maxLife;
    p.color = const Color(0x66B0BEC5);
  }

  void emitSpeedLine(Size screenSize) {
    final p = _getFreeParticle();
    if (p == null) return;

    p.active = true;
    p.type = ParticleType.speedLine;
    final double angle = _random.nextDouble() * 2 * math.pi;
    final double dist = 60.0 + _random.nextDouble() * (screenSize.width * 0.45);
    p.x = screenSize.width * 0.5 + math.cos(angle) * dist;
    p.y = screenSize.height * 0.55 + math.sin(angle) * dist;
    p.vx = math.cos(angle) * (600.0 + _random.nextDouble() * 800.0);
    p.vy = math.sin(angle) * (600.0 + _random.nextDouble() * 800.0);
    p.size = 1.5 + _random.nextDouble() * 2.5;
    p.maxLife = 0.18 + _random.nextDouble() * 0.22;
    p.life = p.maxLife;
    p.color = _random.nextBool() ? GameConstants.neonAqua.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9);
  }

  void emitCrashExplosion({required double screenX, required double screenY}) {
    const List<Color> debrisColors = [
      Colors.white,
      GameConstants.neonCyan,
      GameConstants.neonRed,
      Color(0xFFFF9100),
      Color(0xFF263238),
    ];

    for (int i = 0; i < 70; i++) {
      final p = _getFreeParticle();
      if (p == null) break;

      p.active = true;
      p.type = ParticleType.explosionDebris;
      p.x = screenX;
      p.y = screenY;
      final double angle = _random.nextDouble() * 2 * math.pi;
      final double speed = 90.0 + _random.nextDouble() * 360.0;
      p.vx = math.cos(angle) * speed;
      p.vy = math.sin(angle) * speed - 120.0;
      p.size = 3.0 + _random.nextDouble() * 8.0;
      p.maxLife = 0.6 + _random.nextDouble() * 0.6;
      p.life = p.maxLife;
      p.color = debrisColors[_random.nextInt(debrisColors.length)];
    }
  }

  void update(double dt, Size screenSize, bool isFlying) {
    if (isFlying) {
      for (int i = 0; i < 2; i++) {
        emitSpeedLine(screenSize);
      }
    }

    for (int i = 0; i < maxParticles; i++) {
      final p = _pool[i];
      if (!p.active) continue;

      p.life -= dt;
      if (p.life <= 0.0) {
        p.active = false;
        continue;
      }

      p.x += p.vx * dt;
      p.y += p.vy * dt;

      if (p.type == ParticleType.explosionDebris) {
        p.vy += 450.0 * dt;
      } else if (p.type == ParticleType.tireSmoke) {
        p.size += dt * 18.0;
      }
    }
  }

  void render(Canvas canvas) {
    final Paint particlePaint = Paint();

    for (int i = 0; i < maxParticles; i++) {
      final p = _pool[i];
      if (!p.active) continue;

      final double lifeRatio = (p.life / p.maxLife).clamp(0.0, 1.0);

      switch (p.type) {
        case ParticleType.speedLine:
          particlePaint
            ..color = p.color.withValues(alpha: lifeRatio * 0.75)
            ..strokeWidth = p.size
            ..strokeCap = StrokeCap.round
            ..maskFilter = null;
          const double lineLen = 32.0;
          final double len = math.sqrt(p.vx * p.vx + p.vy * p.vy);
          final double dx = (len > 0) ? (p.vx / len) * lineLen : 0;
          final double dy = (len > 0) ? (p.vy / len) * lineLen : 0;
          canvas.drawLine(Offset(p.x, p.y), Offset(p.x + dx, p.y + dy), particlePaint);
          break;

        case ParticleType.tireSmoke:
          particlePaint
            ..color = p.color.withValues(alpha: lifeRatio * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
          break;

        case ParticleType.plasmaSpark:
          particlePaint
            ..color = p.color.withValues(alpha: lifeRatio)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
          canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
          break;

        case ParticleType.explosionDebris:
          particlePaint
            ..color = p.color.withValues(alpha: lifeRatio)
            ..maskFilter = null;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(p.x, p.y), width: p.size, height: p.size),
            particlePaint,
          );
          break;
      }
    }
  }
}
