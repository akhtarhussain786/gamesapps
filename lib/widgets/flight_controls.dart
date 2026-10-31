import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

/// Multitouch-enabled Flight Controls on bottom-right.
/// Uses per-pointer tracking (Listener) so FLY/FLIP and Joystick work simultaneously.
class FlightControls extends StatelessWidget {
  const FlightControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameController.instance,
      builder: (context, _) {
        final controller = GameController.instance;
        final double airRatio = (controller.airMeter / GameConstants.airMeterMax).clamp(0.0, 1.0);
        final bool canFlip = controller.playerAltitude > 20.0 && !controller.isFlipping;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Smaller Yellow Stunt FLIP Button (+50 score)
            _MultitouchFlipButton(
              enabled: canFlip,
              onPressed: () => controller.triggerFlip(),
            ),

            const SizedBox(width: 16),

            // Big Circular FLY Button with Cyan AIR Ring
            _MultitouchFlyButton(
              airRatio: airRatio,
              airValue: controller.airMeter.toInt(),
              isFlying: controller.isFlying,
              onHoldChanged: (held) => controller.setFlyHeld(held),
            ),
          ],
        );
      },
    );
  }
}

class _MultitouchFlyButton extends StatefulWidget {
  final double airRatio;
  final int airValue;
  final bool isFlying;
  final ValueChanged<bool> onHoldChanged;

  const _MultitouchFlyButton({
    required this.airRatio,
    required this.airValue,
    required this.isFlying,
    required this.onHoldChanged,
  });

  @override
  State<_MultitouchFlyButton> createState() => _MultitouchFlyButtonState();
}

class _MultitouchFlyButtonState extends State<_MultitouchFlyButton> {
  int? _flyPointerId;

  void _handlePointerDown(PointerDownEvent event) {
    if (_flyPointerId != null) return;
    _flyPointerId = event.pointer;
    widget.onHoldChanged(true);
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer != _flyPointerId) return;
    _flyPointerId = null;
    widget.onHoldChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    const double size = 96.0;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FlyButtonPainter(
            airRatio: widget.airRatio,
            isFlying: widget.isFlying,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FLY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: widget.isFlying ? GameConstants.neonAqua : Colors.white,
                    shadows: [
                      Shadow(
                        color: GameConstants.neonCyan,
                        blurRadius: widget.isFlying ? 12.0 : 4.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AIR ${widget.airValue}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: widget.airRatio < 0.25 ? GameConstants.neonRed : GameConstants.neonCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlyButtonPainter extends CustomPainter {
  final double airRatio;
  final bool isFlying;

  _FlyButtonPainter({
    required this.airRatio,
    required this.isFlying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double radius = size.width * 0.44;

    // Background circle
    final Paint bgPaint = Paint()
      ..color = isFlying ? const Color(0xDD0D223B) : const Color(0xB8091325)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Track circle (dim cyan)
    final Paint trackPaint = Paint()
      ..color = GameConstants.neonCyan.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, radius, trackPaint);

    // Active AIR Meter Ring
    final Color ringColor = airRatio < 0.25 ? GameConstants.neonRed : GameConstants.neonCyan;

    // Glow under arc
    final Paint glowPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Paint arcPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = 2 * math.pi * airRatio;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    // Start from top (-pi / 2)
    canvas.drawArc(arcRect, -math.pi * 0.5, sweepAngle, false, glowPaint);
    canvas.drawArc(arcRect, -math.pi * 0.5, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _FlyButtonPainter oldDelegate) {
    return oldDelegate.airRatio != airRatio || oldDelegate.isFlying != isFlying;
  }
}

class _MultitouchFlipButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _MultitouchFlipButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 56.0;

    return Listener(
      onPointerDown: (_) {
        if (enabled) {
          onPressed();
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? const Color(0xE626200A) : const Color(0x6618160E),
            border: Border.all(
              color: enabled ? GameConstants.neonYellow : const Color(0x44FFD600),
              width: 2.0,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: GameConstants.neonYellow.withValues(alpha: 0.35),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                    ),
                  ]
                : [],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rotate_right,
                  color: GameConstants.neonYellow,
                  size: 22,
                ),
                Text(
                  'FLIP',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: GameConstants.neonYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
