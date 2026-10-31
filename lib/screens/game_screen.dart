import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../game/roadster_game.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/virtual_joystick.dart';
import '../widgets/flight_controls.dart';
import '../widgets/status_chips_overlay.dart';
import '../widgets/pause_dialog.dart';
import 'game_over_screen.dart';
import 'splash_screen.dart';

/// Active gameplay screen hosting Flame's 60fps canvas engine and HUD overlay widgets.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RoadsterGame _game;
  final Set<int> _activePointers = <int>{};

  @override
  void initState() {
    super.initState();
    _game = RoadsterGame();
    GameController.instance.resetGame();
  }

  void _pauseGame() {
    GameController.instance.pauseGame();
  }

  void _resumeGame() {
    GameController.instance.resumeGame();
  }

  void _restartGame() {
    _activePointers.clear();
    GameController.instance.resetGame();
    _game.resetGameWorld();
  }

  void _quitToHome() {
    _activePointers.clear();
    GameController.instance.pauseGame();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.bgDark,
      body: Listener(
        // Global multitouch tracker for Touch-To-Drive (Issue 2)
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _activePointers.add(e.pointer);
          GameController.instance.setTouchActive(_activePointers.isNotEmpty);
        },
        onPointerUp: (e) {
          _activePointers.remove(e.pointer);
          GameController.instance.setTouchActive(_activePointers.isNotEmpty);
        },
        onPointerCancel: (e) {
          _activePointers.remove(e.pointer);
          GameController.instance.setTouchActive(_activePointers.isNotEmpty);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Flame Game Engine Canvas
            GameWidget(game: _game),

            // 2. Top HUD Overlay (Score, Level, Distance, Pause button)
            HudOverlay(onPausePressed: _pauseGame),

            // 3. Tactical Warning Status Chips (Below HUD)
            const StatusChipsOverlay(),

            // 4. Bottom Controls: Virtual Joystick (Left) and Flight Controls (Right)
            Positioned(
              left: 20,
              bottom: 24,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: GameController.instance,
                  builder: (context, _) {
                    final isFrozen = GameController.instance.isGameOver || GameController.instance.isPaused;
                    return IgnorePointer(
                      ignoring: isFrozen,
                      child: const VirtualJoystick(),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              right: 20,
              bottom: 24,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: GameController.instance,
                  builder: (context, _) {
                    final isFrozen = GameController.instance.isGameOver || GameController.instance.isPaused;
                    return IgnorePointer(
                      ignoring: isFrozen,
                      child: const FlightControls(),
                    );
                  },
                ),
              ),
            ),

            // 5. Pause Modal Dialog Overlay
            AnimatedBuilder(
              animation: GameController.instance,
              builder: (context, _) {
                if (!GameController.instance.isPaused || GameController.instance.isGameOver) {
                  return const SizedBox.shrink();
                }
                return Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: PauseDialog(
                    onResume: _resumeGame,
                    onRestart: _restartGame,
                    onHome: _quitToHome,
                  ),
                );
              },
            ),

            // 6. Game Over Modal Overlay
            AnimatedBuilder(
              animation: GameController.instance,
              builder: (context, _) {
                if (!GameController.instance.isGameOver) {
                  return const SizedBox.shrink();
                }
                return GameOverScreen(
                  onRetry: _restartGame,
                  onHome: _quitToHome,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
