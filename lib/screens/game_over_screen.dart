import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/audio_manager.dart';
import '../core/game_state.dart';

/// Game Over Modal Overlay presenting final score, high score record,
/// level reached, crash forensics, and Retry/Home actions.
class GameOverScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const GameOverScreen({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final controller = GameController.instance;
    final bool isNewBest = controller.score >= controller.bestScore && controller.score > 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
          decoration: GameTheme.glassPanel(
            borderColor: GameConstants.neonRed,
            borderRadius: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: GameConstants.neonRed.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: GameConstants.neonRed, width: 1.0),
                ),
                child: const Text(
                  'CRASH DETECTED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: GameConstants.neonRed,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Crash Reason
              Text(
                controller.crashReason.isNotEmpty ? controller.crashReason : 'SYSTEM OVERRIDE',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Color(0xFF90A4AE),
                ),
              ),
              const SizedBox(height: 20),

              // New Record Indicator
              if (isNewBest) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: GameConstants.neonYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: GameConstants.neonYellow, width: 1.0),
                  ),
                  child: const Text(
                    '★ NEW BEST RECORD! ★',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: GameConstants.neonYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Final Score
              const Text(
                'FINAL SCORE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: Color(0xFF78909C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.score.toString().padLeft(5, '0'),
                style: GameTheme.lcdLarge.copyWith(fontSize: 34),
              ),
              const SizedBox(height: 18),

              // Stats Row (Best, Level, Distance)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
                decoration: BoxDecoration(
                  color: const Color(0x6608101E),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('BEST', controller.bestScore.toString()),
                    Container(width: 1, height: 28, color: const Color(0xFF263238)),
                    _buildStatCol('LVL', controller.level.toString().padLeft(2, '0')),
                    Container(width: 1, height: 28, color: const Color(0xFF263238)),
                    _buildStatCol('DIST', '${controller.distanceMeters}M'),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Action Buttons
              // 1. RETRY Button (Primary)
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playButtonClick();
                  onRetry();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  decoration: BoxDecoration(
                    color: GameConstants.neonCyan,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: GameConstants.neonCyan.withValues(alpha: 0.4),
                        blurRadius: 14.0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'RETRY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. HOME Button
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playButtonClick();
                  onHome();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0x6610192A),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: const Color(0xFF37474F),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'MAIN MENU',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: Color(0xFF78909C),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
