import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/game_state.dart';
import '../widgets/pause_dialog.dart';

/// Game-over panel: crash reason, final score, best/level/distance, and
/// Retry / Main Menu. It appears after a short delay so the crash slow-mo is
/// actually visible instead of being covered instantly.
class GameOverScreen extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const GameOverScreen({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameController.instance;
    final bool isNewBest = controller.isNewBest;

    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _visible ? 1.0 : 0.0,
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(22.0, 24.0, 22.0, 22.0),
              decoration: GameTheme.glassPanel(borderColor: GameConstants.neonRed, borderRadius: 18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('CRASHED', style: GameTheme.heading.copyWith(color: GameConstants.neonRed)),
                  const SizedBox(height: 8),
                  Text(
                    controller.crashReason.isNotEmpty ? controller.crashReason : 'RUN ENDED',
                    textAlign: TextAlign.center,
                    style: GameTheme.label.copyWith(fontSize: 13, color: GameConstants.textMuted, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 22),
                  if (isNewBest) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: GameConstants.neonGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'NEW BEST',
                        style: GameTheme.label.copyWith(fontSize: 12, color: GameConstants.neonGreen),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Text('FINAL SCORE', style: GameTheme.caption),
                  const SizedBox(height: 6),
                  Text(
                    controller.score.toString().padLeft(6, '0'),
                    style: GameTheme.numberLarge.copyWith(fontSize: 40),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('BEST', controller.bestScore.toString()),
                        _divider(),
                        _stat('LEVEL', controller.level.toString()),
                        _divider(),
                        _stat('DISTANCE', '${controller.distanceMeters} m'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  GameMenuButton(label: 'RETRY', icon: Icons.replay_rounded, primary: true, onTap: widget.onRetry),
                  const SizedBox(height: 10),
                  GameMenuButton(label: 'MAIN MENU', icon: Icons.home_rounded, onTap: widget.onHome),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: const Color(0x22FFFFFF));

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GameTheme.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        Text(value, style: GameTheme.numberSmall.copyWith(fontSize: 15, color: Colors.white)),
      ],
    );
  }
}
