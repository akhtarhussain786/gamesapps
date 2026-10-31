import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/audio_manager.dart';

/// Modal pause menu: Resume, Restart, Sound toggle and Main Menu.
class PauseDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  late bool _soundOn;

  @override
  void initState() {
    super.initState();
    _soundOn = AudioManager.instance.isSoundEnabled;
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    AudioManager.instance.setSoundEnabled(_soundOn);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(22.0, 26.0, 22.0, 22.0),
        decoration: GameTheme.glassPanel(borderRadius: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PAUSED', style: GameTheme.heading),
            const SizedBox(height: 24),
            GameMenuButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onTap: widget.onResume,
            ),
            const SizedBox(height: 10),
            GameMenuButton(label: 'RESTART', icon: Icons.refresh_rounded, onTap: widget.onRestart),
            const SizedBox(height: 10),
            GameMenuButton(
              label: _soundOn ? 'SOUND ON' : 'SOUND OFF',
              icon: _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              tint: _soundOn ? null : GameConstants.neonRed,
              onTap: _toggleSound,
            ),
            const SizedBox(height: 10),
            GameMenuButton(label: 'MAIN MENU', icon: Icons.home_rounded, onTap: widget.onHome),
          ],
        ),
      ),
    );
  }
}

/// Shared menu button: a solid cyan primary action, or a quiet outlined one.
class GameMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final Color? tint;
  final VoidCallback onTap;

  const GameMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = primary ? const Color(0xFF041018) : (tint ?? Colors.white);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AudioManager.instance.playButtonClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: primary ? 52 : 46,
        decoration: BoxDecoration(
          color: primary ? GameConstants.neonCyan : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(12.0),
          border: primary ? null : Border.all(color: (tint ?? Colors.white).withValues(alpha: 0.18)),
          boxShadow: primary
              ? [BoxShadow(color: GameConstants.neonCyan.withValues(alpha: 0.35), blurRadius: 16.0)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Text(label, style: GameTheme.button.copyWith(fontSize: primary ? 16 : 14, color: fg)),
          ],
        ),
      ),
    );
  }
}
