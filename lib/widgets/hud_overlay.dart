import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/game_state.dart';
import 'status_chips_overlay.dart';

/// Top HUD: score card (score, level progress, distance) on the left, speed
/// readout and pause button on the right, and the status chip centred below.
/// Everything sits inside the SafeArea, so nothing collides with a notch.
class HudOverlay extends StatelessWidget {
  final VoidCallback onPausePressed;

  const HudOverlay({super.key, required this.onPausePressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 0.0),
        child: AnimatedBuilder(
          animation: GameController.instance,
          builder: (context, _) {
            final c = GameController.instance;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScoreCard(controller: c),
                    const Spacer(),
                    _SpeedCard(kmh: c.speedKmh),
                    const SizedBox(width: 8),
                    IgnorePointer(
                      ignoring: c.isGameOver,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: c.isGameOver ? 0.0 : 1.0,
                        child: _PauseButton(onTap: onPausePressed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatusChipsOverlay(chip: c.currentStatusChip),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final GameController controller;
  const _ScoreCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 9.0, 12.0, 10.0),
      decoration: GameTheme.glassPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SCORE', style: GameTheme.caption),
          const SizedBox(height: 5),
          Text(c.score.toString().padLeft(6, '0'), style: GameTheme.numberLarge),
          const SizedBox(height: 9),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: GameConstants.neonCyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'LV ${c.level}',
                  style: GameTheme.label.copyWith(fontSize: 12, color: GameConstants.neonCyan, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.0),
                  child: LinearProgressIndicator(
                    value: c.levelProgress,
                    backgroundColor: const Color(0xFF1C2638),
                    valueColor: const AlwaysStoppedAnimation<Color>(GameConstants.neonCyan),
                    minHeight: 6.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${c.distanceMeters} m', style: GameTheme.numberSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final int kmh;
  const _SpeedCard({required this.kmh});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 68),
      padding: const EdgeInsets.fromLTRB(10.0, 9.0, 10.0, 9.0),
      decoration: GameTheme.glassPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('KM/H', style: GameTheme.caption),
          const SizedBox(height: 5),
          Text('$kmh', style: GameTheme.numberMedium),
        ],
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PauseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: GameTheme.glassPanel(borderRadius: 24.0),
        child: const Icon(Icons.pause_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
