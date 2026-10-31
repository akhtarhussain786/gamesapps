import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../core/theme.dart';

/// The single tactical alert chip shown under the HUD.
///
/// It is keyed by the chip's *id*, not its text, so a countdown such as
/// "PILE AHEAD 42M -> 41M -> 40M" updates in place instead of re-playing the
/// enter animation several times a second.
class StatusChipsOverlay extends StatelessWidget {
  final StatusChipInfo? chip;

  const StatusChipsOverlay({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    final StatusChipInfo? chip = this.chip;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: chip == null
            ? const SizedBox(key: ValueKey('none'), height: 34)
            : _Chip(key: ValueKey(chip.id), text: chip.text, color: toneColor(chip.tone)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xEE0A1222),
        borderRadius: BorderRadius.circular(17.0),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 12.0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(text, style: GameTheme.label.copyWith(fontSize: 15, color: Colors.white)),
        ],
      ),
    );
  }
}
