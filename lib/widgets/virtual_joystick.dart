import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

/// Left-hand Virtual Joystick with per-pointer tracking (multitouch compatible).
/// Radius = 60, dead zone = 10%. Steering is NOT inverted (right moves right).
class VirtualJoystick extends StatefulWidget {
  final double radius;
  final double knobRadius;

  const VirtualJoystick({
    super.key,
    this.radius = GameConstants.joystickRadius, // 60.0
    this.knobRadius = 26.0,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _activePointerId;
  Offset _knobPosition = Offset.zero;

  void _handlePointerDown(PointerDownEvent event, Offset center) {
    if (_activePointerId != null) return; // Already tracking another finger
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
    setState(() {
      _knobPosition = Offset.zero;
    });
    // On release, knob returns to center and steer eases to 0
    GameController.instance.setJoystickSteer(0.0, false);
  }

  void _updateSteer(Offset localPos, Offset center) {
    final Offset delta = localPos - center;
    final double dist = delta.distance;

    Offset clampedDelta = delta;
    if (dist > widget.radius) {
      clampedDelta = Offset.fromDirection(delta.direction, widget.radius);
    }

    setState(() {
      _knobPosition = clampedDelta;
    });

    // Dead zone 10% (6.0px for radius 60)
    final double deadZone = widget.radius * GameConstants.joystickDeadZone;
    final double dx = clampedDelta.dx;
    double steer = 0.0;

    if (dx.abs() > deadZone) {
      // Linear scaling outside dead zone, keeping right as positive (right moves right)
      final double magnitude = (dx.abs() - deadZone) / (widget.radius - deadZone);
      steer = (dx.sign * magnitude).clamp(-1.0, 1.0);
    }

    // Report steer and indicate touch is active
    GameController.instance.setJoystickSteer(steer, true);
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.radius * 2.5;
    final Offset center = Offset(size * 0.5, size * 0.5);

    return SizedBox(
      width: size,
      height: size,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _handlePointerDown(e, center),
        onPointerMove: (e) => _handlePointerMove(e, center),
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: CustomPaint(
          painter: _JoystickPainter(
            radius: widget.radius,
            knobRadius: widget.knobRadius,
            knobPosition: _knobPosition,
            isTracking: _activePointerId != null,
          ),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final double radius;
  final double knobRadius;
  final Offset knobPosition;
  final bool isTracking;

  _JoystickPainter({
    required this.radius,
    required this.knobRadius,
    required this.knobPosition,
    required this.isTracking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);

    // 1. Dark circular base
    final Paint basePaint = Paint()
      ..color = const Color(0xB8091122)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // Outer cyan accent border
    final Paint ringPaint = Paint()
      ..color = GameConstants.neonCyan.withValues(alpha: isTracking ? 0.65 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, ringPaint);

    // Subtle guidelines
    final Paint guidePaint = Paint()
      ..color = GameConstants.neonCyan.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - radius * 0.65, center.dy), Offset(center.dx + radius * 0.65, center.dy), guidePaint);
    canvas.drawLine(Offset(center.dx, center.dy - radius * 0.65), Offset(center.dx, center.dy + radius * 0.65), guidePaint);

    // 2. Movable White/Cyan Knob
    final Offset knobCenter = center + knobPosition;

    // Knob Drop Shadow
    final Paint knobShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawCircle(knobCenter + const Offset(0, 3), knobRadius, knobShadow);

    // Knob Body
    final Paint knobPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFE0F7FA),
          GameConstants.neonCyan.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromCircle(center: knobCenter, radius: knobRadius));
    canvas.drawCircle(knobCenter, knobRadius, knobPaint);

    // Knob Edge Trim
    final Paint knobTrim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(knobCenter, knobRadius, knobTrim);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.knobPosition != knobPosition || oldDelegate.isTracking != isTracking;
  }
}
