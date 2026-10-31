import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/game_state.dart';

/// Top HUD Overlay: Top-left stats panel (zero-padded LCD score, level, progress bar, distance)
/// and top-right round glass pause button.
class HudOverlay extends StatelessWidget {
  final VoidCallback onPausePressed;

  const HudOverlay({
    super.key,
    required this.onPausePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top-Left Statistics Panel
            AnimatedBuilder(
              animation: GameController.instance,
              builder: (context, _) {
                final controller = GameController.instance;
                final String formattedScore = controller.score.toString().padLeft(5, '0');
                final String formattedLevel = controller.level.toString().padLeft(2, '0');
                final String formattedDistance = '${controller.distanceMeters} M';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: GameTheme.glassPanel(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Score & Level Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedScore,
                            style: GameTheme.lcdLarge,
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: GameConstants.neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(
                                color: GameConstants.neonCyan.withValues(alpha: 0.5),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              'LVL $formattedLevel',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: GameConstants.neonCyan,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Level Progress Bar
                      SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2.0),
                          child: LinearProgressIndicator(
                            value: controller.levelProgress,
                            backgroundColor: const Color(0xFF1E2838),
                            valueColor: const AlwaysStoppedAnimation<Color>(GameConstants.neonCyan),
                            minHeight: 3.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Distance display
                      Text(
                        formattedDistance,
                        style: GameTheme.lcdSmall,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Top-Right Circular Pause Button
            GestureDetector(
              onTap: onPausePressed,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xCC09101E),
                  border: Border.all(
                    color: GameConstants.neonCyan.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GameConstants.neonCyan.withValues(alpha: 0.2),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.pause_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
