import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/audio_manager.dart';

/// Modal Pause Dialog offering Resume, Restart, Sound Toggle, and Home options.
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
    setState(() {
      _soundOn = !_soundOn;
    });
    AudioManager.instance.setSoundEnabled(_soundOn);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 310,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        decoration: GameTheme.glassPanel(
          borderColor: GameConstants.neonCyan,
          borderRadius: 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'PAUSED',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: GameConstants.neonCyan,
                shadows: [
                  Shadow(
                    color: GameConstants.neonCyan,
                    blurRadius: 16.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SYSTEM STANDBY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: Color(0xFF78909C),
              ),
            ),
            const SizedBox(height: 28),

            // Resume Button
            _buildDialogButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              isPrimary: true,
              onTap: widget.onResume,
            ),
            const SizedBox(height: 14),

            // Restart Button
            _buildDialogButton(
              label: 'RESTART',
              icon: Icons.refresh_rounded,
              isPrimary: false,
              onTap: widget.onRestart,
            ),
            const SizedBox(height: 14),

            // Sound Toggle Button
            _buildDialogButton(
              label: _soundOn ? 'SOUND: ON' : 'SOUND: OFF',
              icon: _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              isPrimary: false,
              highlightColor: _soundOn ? GameConstants.neonCyan : GameConstants.neonRed,
              onTap: _toggleSound,
            ),
            const SizedBox(height: 14),

            // Home Button
            _buildDialogButton(
              label: 'MAIN MENU',
              icon: Icons.home_rounded,
              isPrimary: false,
              onTap: widget.onHome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    Color? highlightColor,
    required VoidCallback onTap,
  }) {
    final Color activeColor = highlightColor ?? (isPrimary ? GameConstants.neonCyan : Colors.white);

    return GestureDetector(
      onTap: () {
        AudioManager.instance.playButtonClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isPrimary ? GameConstants.neonCyan.withValues(alpha: 0.18) : const Color(0x6610192A),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: activeColor.withValues(alpha: isPrimary ? 0.9 : 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: activeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
