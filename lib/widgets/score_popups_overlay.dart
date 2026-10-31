import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/theme.dart';

/// Floating reward text ("+300 CLEAN LANDING") that rises from above the car
/// and fades out. Rewards live here, separate from the warning chip, so they
/// are never overwritten by hazard alerts.
class ScorePopupsOverlay extends StatelessWidget {
  const ScorePopupsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: GameController.instance,
        builder: (context, _) {
          final popups = GameController.instance.popups;
          if (popups.isEmpty) return const SizedBox.shrink();

          return LayoutBuilder(
            builder: (context, constraints) {
              final double h = constraints.maxHeight;
              final double w = constraints.maxWidth;
              const double scale = GameConstants.cameraDepth / GameConstants.playerDepth;
              final double groundY = h * GameConstants.playerGroundYRatio;
              final double carHeight = scale * GameConstants.playerCarWidth * (w * 0.5) * 0.56;
              final List<Widget> children = [];

              for (int i = 0; i < popups.length; i++) {
                final p = popups[i];
                final double t = (p.age / ScorePopup.lifetime).clamp(0.0, 1.0);
                final int stackIndex = popups.length - 1 - i; // newest at the bottom
                final double carTop = groundY - scale * p.altitude * (h * 0.5) - carHeight;
                final double y = carTop - 36.0 - t * 70.0 - stackIndex * 32.0;
                final double opacity = t < 0.1 ? t / 0.1 : (t > 0.7 ? (1.0 - t) / 0.3 : 1.0);
                final double popScale = t < 0.12 ? 0.7 + (t / 0.12) * 0.3 : 1.0;
                final Color color = toneColor(p.tone);

                children.add(Positioned(
                  left: 0,
                  right: 0,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: popScale,
                      child: Text(
                        p.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontSize: p.big ? 26 : 19,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                          color: color,
                          shadows: const [
                            Shadow(color: Color(0xE6000000), blurRadius: 6.0, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ));
              }
              return Stack(children: children);
            },
          );
        },
      ),
    );
  }
}
