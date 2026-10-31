import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/audio_manager.dart';
import '../core/game_state.dart';
import 'game_screen.dart';

/// Splash Screen featuring radial dark-blue glow, stylized ROADSTER RUSH branding,
/// segmented 12-block loading bar, BEST score chip, and sound toggle chip.
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 0.95,
            colors: [
              GameConstants.darkBlueGlow,
              Color(0xFF070F1E),
              GameConstants.bgDark,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar: BEST Score Chip & Sound Toggle Chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // BEST Score Chip
                    AnimatedBuilder(
                      animation: GameController.instance,
                      builder: (context, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: const Color(0xCC091224),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: GameConstants.neonCyan.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: GameConstants.neonYellow, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'BEST: ${GameController.instance.bestScore}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Sound ON/OFF Chip
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          AudioManager.instance.toggleSound();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xCC091224),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: AudioManager.instance.isSoundEnabled
                                ? GameConstants.neonCyan.withValues(alpha: 0.5)
                                : GameConstants.neonRed.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AudioManager.instance.isSoundEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: AudioManager.instance.isSoundEnabled
                                  ? GameConstants.neonCyan
                                  : GameConstants.neonRed,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AudioManager.instance.isSoundEnabled ? 'SOUND: ON' : 'SOUND: OFF',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AudioManager.instance.isSoundEnabled
                                    ? GameConstants.neonCyan
                                    : GameConstants.neonRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Central Hero Branding & Action
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small Subheader
                  const Text(
                    'F1 RACE · REIMAGINED',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      color: GameConstants.neonCyan,
                      shadows: [
                        Shadow(color: GameConstants.neonCyan, blurRadius: 10.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Logo: "ROADSTER" in italic with neon "RUSH" box
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ROADSTER',
                        style: GameTheme.logoTitle,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: GameConstants.neonCyan,
                          borderRadius: BorderRadius.circular(4.0),
                          boxShadow: const [
                            BoxShadow(
                              color: GameConstants.neonCyan,
                              blurRadius: 16.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'RUSH',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // Loading Bar or Big TAP TO START Button
                  if (_isLoading) ...[
                    // Segmented 12-block loading bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(12, (index) {
                          final bool isLit = index < _loadedBlocks;
                          return Container(
                            width: 16,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: isLit ? GameConstants.neonCyan : const Color(0xFF131D2E),
                              borderRadius: BorderRadius.circular(2.0),
                              boxShadow: isLit
                                  ? const [
                                      BoxShadow(
                                        color: GameConstants.neonCyan,
                                        blurRadius: 8.0,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: Color(0xFF78909C),
                      ),
                    ),
                  ] else ...[
                    // Pulsing Big Cyan "TAP TO START" Button
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: GestureDetector(
                        onTap: _startGame,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 42.0, vertical: 16.0),
                          decoration: BoxDecoration(
                            color: GameConstants.neonCyan,
                            borderRadius: BorderRadius.circular(32.0),
                            boxShadow: [
                              BoxShadow(
                                color: GameConstants.neonCyan.withValues(alpha: 0.65),
                                blurRadius: 24.0,
                                spreadRadius: 3.0,
                              ),
                            ],
                          ),
                          child: const Text(
                            'TAP TO START',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Footer: Non-commercial fan project
              const Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Text(
                  'Non-commercial fan project',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                    color: Color(0xFF546E7A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
