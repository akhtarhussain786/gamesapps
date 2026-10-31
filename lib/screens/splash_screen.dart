import 'dart:async';
import 'package:flutter/material.dart';
import '../game/components/roadster_painter.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/audio_manager.dart';
import '../core/game_state.dart';
import 'game_screen.dart';

/// Title screen: the player's roadster as the hero image, the ROADSTER RUSH
/// logo, a short loading sequence, BEST score and a sound toggle.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  int _loadedBlocks = 0;
  bool _isLoading = true;
  String _statusText = 'INITIALIZING ROAD GEOMETRY...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadGameData();
  }

  Future<void> _loadGameData() async {
    await AudioManager.instance.init();
    await GameController.instance.loadBestScore();

    // Animate the 12-block loading sequence
    const List<String> statusMessages = [
      'INITIALIZING ROAD GEOMETRY...',
      'CALIBRATING ION THRUSTERS...',
      'RENDERING SKYLINE MESH...',
      'SYSTEMS READY',
    ];

    for (int i = 1; i <= 12; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() {
        _loadedBlocks = i;
        _statusText = statusMessages[(i ~/ 3.5).clamp(0, statusMessages.length - 1)];
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    AudioManager.instance.playButtonClick();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool soundOn = AudioManager.instance.isSoundEnabled;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1630), Color(0xFF0A1022), GameConstants.bgDark],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: BEST score & sound toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: GameController.instance,
                      builder: (context, _) => _TopChip(
                        icon: Icons.emoji_events_rounded,
                        iconColor: GameConstants.neonAmber,
                        label: 'BEST  ${GameController.instance.bestScore}',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => AudioManager.instance.toggleSound()),
                      child: _TopChip(
                        icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        iconColor: soundOn ? GameConstants.neonCyan : GameConstants.neonRed,
                        label: soundOn ? 'SOUND ON' : 'SOUND OFF',
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Hero car on a lit floor
              SizedBox(
                width: 260,
                height: 170,
                child: CustomPaint(painter: _HeroCarPainter()),
              ),
              const SizedBox(height: 28),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ROADSTER', style: GameTheme.logoTitle),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: GameConstants.playerMagenta,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          'RUSH',
                          style: GameTheme.logoTitle.copyWith(fontSize: 26, shadows: const []),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'FLY OVER THE PILE-UP',
                style: GameTheme.label.copyWith(fontSize: 15, letterSpacing: 4.0, color: GameConstants.neonCyan),
              ),

              const Spacer(flex: 2),

              // Loading bar or start button
              SizedBox(
                height: 90,
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(12, (index) {
                              final bool isLit = index < _loadedBlocks;
                              return Container(
                                width: 14,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                decoration: BoxDecoration(
                                  color: isLit ? GameConstants.neonCyan : const Color(0xFF1A2438),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          Text(_statusText, style: GameTheme.caption),
                        ],
                      )
                    : Center(
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: GestureDetector(
                            onTap: _startGame,
                            child: Container(
                              width: 240,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: GameConstants.neonCyan,
                                borderRadius: BorderRadius.circular(29.0),
                                boxShadow: [
                                  BoxShadow(color: GameConstants.neonCyan.withValues(alpha: 0.4), blurRadius: 22.0),
                                ],
                              ),
                              child: Text(
                                'TAP TO START',
                                style: GameTheme.button.copyWith(fontSize: 18, color: const Color(0xFF041018)),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),

              const Spacer(flex: 1),

              // How to play
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 18.0),
                child: Text(
                  'HOLD ANYWHERE TO DRIVE  ·  STEER WITH LEFT THUMB\nHOLD FLY TO JUMP OVER PILES',
                  textAlign: TextAlign.center,
                  style: GameTheme.caption.copyWith(fontSize: 10, letterSpacing: 1.4, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _TopChip({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: GameTheme.glassPanel(borderRadius: 18.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GameTheme.label.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Paints the player's roadster on a softly lit floor for the title screen.
class _HeroCarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width * 0.92;
    final Offset ground = Offset(size.width * 0.5, size.height * 0.94);

    // Floor glow & shadow
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: size.width * 1.1, height: size.height * 0.22),
      Paint()
        ..color = GameConstants.neonCyan.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
    );
    canvas.drawOval(
      Rect.fromCenter(center: ground.translate(0, -2), width: w * 1.05, height: w * 0.11),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    canvas.save();
    canvas.translate(ground.dx, ground.dy);
    RoadsterPainter.paintRear(canvas, w);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
