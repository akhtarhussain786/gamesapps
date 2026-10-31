import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

/// Left-thumb steering pad. Steering is the only axis the game reads, so the
/// control is drawn as a horizontal track (no misleading up/down guides).
/// Uses per-pointer tracking so it works while FLY is held with the other thumb.
class VirtualJoystick extends StatefulWidget {
  /// Max knob travel from centre, in logical pixels.
  final double radius;
  final double knobRadius;

  const VirtualJoystick({
    super.key,
    this.radius = GameConstants.joystickRadius,
    this.knobRadius = 26.0,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _activePointerId;
  double _knobX = 0.0;

  void _handlePointerDown(PointerDownEvent event, Offset center) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    _updateSteer(event.localPosition, center);
  }

  void _handlePointerMove(PointerMoveEvent event, Offset center) {
    if (event.pointer != _activePointerId) return;
    _updateSteer(event.localPosition, center);
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    setState(() => _knobX = 0.0);
    GameController.instance.setJoystickSteer(0.0, false);
  }

  void _updateSteer(Offset localPos, Offset center) {
    final double dx = (localPos.dx - center.dx).clamp(-widget.radius, widget.radius);
    setState(() => _knobX = dx);

    final double deadZone = widget.radius * GameConstants.joystickDeadZone;
    double steer = 0.0;
    if (dx.abs() > deadZone) {
      final double magnitude = (dx.abs() - deadZone) / (widget.radius - deadZone);
      steer = (dx.sign * magnitude).clamp(-1.0, 1.0);
    }
    GameController.instance.setJoystickSteer(steer, true);
  }

  @override
  Widget build(BuildContext context) {
    // Touch area is generous (taller than the drawn track) for thumbs.
    final double width = widget.radius * 2.0 + widget.knobRadius * 2.0 + 12.0;
    const double height = 120.0;
    final Offset center = Offset(width * 0.5, height * 0.62);

    return SizedBox(
      width: width,
      height: height,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _handlePointerDown(e, center),
        onPointerMove: (e) => _handlePointerMove(e, center),
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: CustomPaint(
          painter: _SteerPadPainter(
            center: center,
            radius: widget.radius,
            knobRadius: widget.knobRadius,
            knobX: _knobX,
            isTracking: _activePointerId != null,
          ),
        ),
      ),
    );
  }
}

class _SteerPadPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double knobRadius;
  final double knobX;
  final bool isTracking;

  _SteerPadPainter({
    required this.center,
    required this.radius,
    required this.knobRadius,
    required this.knobX,
    required this.isTracking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackH = knobRadius * 2.0 + 10.0;
    final RRect track = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: radius * 2.0 + knobRadius * 2.0 + 10.0, height: trackH),
      Radius.circular(trackH * 0.5),
    );

    canvas.drawRRect(track.shift(const Offset(0, 3)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(track, Paint()..color = const Color(0xCC0A1222));
    canvas.drawRRect(
      track,
      Paint()
        ..color = GameConstants.neonCyan.withValues(alpha: isTracking ? 0.6 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Direction chevrons; the one you're steering towards lights up.
    final double steer = (knobX / radius).clamp(-1.0, 1.0);
    _chevron(canvas, Offset(center.dx - radius - knobRadius * 0.35, center.dy), -1, steer < -0.1);
    _chevron(canvas, Offset(center.dx + radius + knobRadius * 0.35, center.dy), 1, steer > 0.1);

    // Knob
    final Offset k = Offset(center.dx + knobX, center.dy);
    canvas.drawCircle(
      k + const Offset(0, 3),
      knobRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );
    canvas.drawCircle(
      k,
      knobRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Colors.white, Color(0xFFCFF8FF), Color(0xFF5FD8EA)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: k, radius: knobRadius)),
    );
    // Grip lines
    final Paint grip = Paint()
      ..color = const Color(0x660A1222)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (final double dx in const [-6.0, 0.0, 6.0]) {
      canvas.drawLine(Offset(k.dx + dx, k.dy - 8), Offset(k.dx + dx, k.dy + 8), grip);
    }
  }

  void _chevron(Canvas canvas, Offset c, int dir, bool active) {
    const double s = 7.0;
    final Path p = Path()
      ..moveTo(c.dx - dir * s * 0.5, c.dy - s)
      ..lineTo(c.dx + dir * s * 0.5, c.dy)
      ..lineTo(c.dx - dir * s * 0.5, c.dy + s);
    canvas.drawPath(
      p,
      Paint()
        ..color = active ? GameConstants.neonCyan : Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SteerPadPainter old) {
    return old.knobX != knobX || old.isTracking != isTracking || old.center != center;
  }
}

