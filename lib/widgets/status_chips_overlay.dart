import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

/// Floating dynamic status chips placed under the top HUD bar.
/// Displays tactical road alerts with pulsating colored indicator dots.
class StatusChipsOverlay extends StatelessWidget {
  const StatusChipsOverlay({super.key});

  Color _resolveDotColor(StatusDotColor color) {
    switch (color) {
      case StatusDotColor.green:
        return GameConstants.neonGreen;
      case StatusDotColor.yellow:
        return GameConstants.neonYellow;
      case StatusDotColor.red:
        return GameConstants.neonRed;
      case StatusDotColor.cyan:
        return GameConstants.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GameController.instance,
      builder: (context, _) {
        final chip = GameController.instance.currentStatusChip;

        return Positioned(
          top: 96,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: (chip != null)
                  ? Container(
                      key: ValueKey(chip.text),
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xEE081224),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: _resolveDotColor(chip.dotColor).withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _resolveDotColor(chip.dotColor).withValues(alpha: 0.25),
                            blurRadius: 12.0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing Colored Indicator Dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _resolveDotColor(chip.dotColor),
                              boxShadow: [
                                BoxShadow(
                                  color: _resolveDotColor(chip.dotColor),
                                  blurRadius: 6.0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chip.text,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
