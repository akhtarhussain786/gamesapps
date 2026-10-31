import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/theme.dart';

/// Bottom-right flight controls: a big FLY button wrapped by the AIR gauge,
/// and a smaller FLIP button. Per-pointer tracking keeps them usable while the
/// other thumb steers.
class FlightControls extends StatelessWidget {
  const FlightControls({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameController.instance,
      builder: (context, _) {
        final controller = GameController.instance;
        final double airRatio = (controller.airMeter / GameConstants.airMeterMax).clamp(0.0, 1.0);
        final bool canFlip = controller.isAirborne && !controller.isFlipping && !controller.isGameOver;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _FlipButton(
              enabled: canFlip,
              onPressed: () => controller.triggerFlip(),
            ),
            const SizedBox(width: 14),
            _FlyButton(
              airRatio: airRatio,
              isFlying: controller.isFlying,
              cue: controller.flyCue,
              onHoldChanged: (held) => controller.setFlyHeld(held),
            ),
          ],
        );
      },
    );
  }
}

class _FlyButton extends StatefulWidget {
  final double airRatio;
  final bool isFlying;
  final bool cue;
  final ValueChanged<bool> onHoldChanged;

  const _FlyButton({
    required this.airRatio,
    required this.isFlying,
    required this.cue,
    required this.onHoldChanged,
  });

  @override
  State<_FlyButton> createState() => _FlyButtonState();
}

class _FlyButtonState extends State<_FlyButton> {
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
    const double size = 104.0;
    final bool low = widget.airRatio < 0.25;
    // The controller notifies every frame, so a time-based pulse is enough.
    final double pulse = widget.cue ? 0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch / 90.0) : 0.0;

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
            cuePulse: pulse,
            cue: widget.cue,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FLY',
                  style: GameTheme.button.copyWith(
                    fontSize: 22,
                    color: widget.isFlying ? GameConstants.neonAqua : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  low ? 'LOW AIR' : (widget.isFlying ? 'LIFT' : 'HOLD'),
                  style: GameTheme.caption.copyWith(
                    fontSize: 10,
                    color: low ? GameConstants.neonRed : GameConstants.neonCyan.withValues(alpha: 0.8),
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
  final bool cue;
  final double cuePulse;

  _FlyButtonPainter({
    required this.airRatio,
    required this.isFlying,
    required this.cue,
    required this.cuePulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width * 0.42;

    // Call-to-action halo when a pile needs clearing.
    if (cue) {
      canvas.drawCircle(
        center,
        radius + 6.0 + cuePulse * 4.0,
        Paint()
          ..color = GameConstants.neonRed.withValues(alpha: 0.35 + 0.45 * cuePulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // Button face
    canvas.drawCircle(
      center,
      radius - 4.0,
      Paint()
        ..shader = RadialGradient(
          colors: isFlying
              ? const [Color(0xFF15405A), Color(0xFF0A1D2E)]
              : const [Color(0xFF14233A), Color(0xFF0A1222)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // AIR track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1C2A40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0,
    );

    // AIR gauge
    final Color ringColor = airRatio < 0.25 ? GameConstants.neonRed : GameConstants.neonCyan;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    final double sweep = 2 * math.pi * airRatio;
    if (isFlying) {
      canvas.drawArc(
        arcRect,
        -math.pi * 0.5,
        sweep,
        false,
        Paint()
          ..color = ringColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }
    canvas.drawArc(
      arcRect,
      -math.pi * 0.5,
      sweep,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FlyButtonPainter old) {
    return old.airRatio != airRatio || old.isFlying != isFlying || old.cue != cue || old.cuePulse != cuePulse;
  }
}

class _FlipButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _FlipButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const double size = 62.0;
    const Color accent = GameConstants.playerMagenta;

    return Listener(
      onPointerDown: (_) {
        if (enabled) onPressed();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? const Color(0xFF2A0D1F) : const Color(0xCC0A1222),
              border: Border.all(
                color: enabled ? accent : const Color(0xFF2E3A4E),
                width: 2.0,
              ),
              boxShadow: enabled ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12.0)] : const [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.threesixty_rounded, color: enabled ? accent : const Color(0xFF55647A), size: 24),
                Text(
                  'FLIP',
                  style: GameTheme.caption.copyWith(
                    fontSize: 11,
                    color: enabled ? accent : const Color(0xFF55647A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: enabled ? 0.0 : 1.0,
              child: Text('IN AIR ONLY', style: GameTheme.caption.copyWith(fontSize: 9, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}
