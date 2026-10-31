import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../game/roadster_game.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/virtual_joystick.dart';
import '../widgets/flight_controls.dart';
import '../widgets/score_popups_overlay.dart';
import '../widgets/pause_dialog.dart';
import 'game_over_screen.dart';
import 'splash_screen.dart';

/// Active gameplay screen hosting the Flame canvas and the HUD/control overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final RoadsterGame _game;
  final Set<int> _activePointers = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = RoadsterGame();
    GameController.instance.resetGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause automatically when the app is backgrounded or a call comes in, so
  /// the player doesn't return to a crashed run.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _activePointers.clear();
      final c = GameController.instance;
      c.setTouchActive(false);
      c.setFlyHeld(false);
      c.setJoystickSteer(0.0, false);
      c.pauseGame();
    }
  }

  void _pauseGame() => GameController.instance.pauseGame();

  void _resumeGame() => GameController.instance.resumeGame();

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

  void _updateTouch() => GameController.instance.setTouchActive(_activePointers.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.bgDark,
      body: Listener(
        // Touch-to-drive: any finger on the screen keeps the throttle open.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _activePointers.add(e.pointer);
          _updateTouch();
        },
        onPointerUp: (e) {
          _activePointers.remove(e.pointer);
          _updateTouch();
        },
        onPointerCancel: (e) {
          _activePointers.remove(e.pointer);
          _updateTouch();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Game canvas
            GameWidget(game: _game),

            // 2. Reward popups above the car
            const Positioned.fill(child: ScorePopupsOverlay()),

            // 3. HUD (score, speed, pause, status chip)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: HudOverlay(onPausePressed: _pauseGame),
            ),

            // 4. Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 0.0, 14.0, 14.0),
                  child: AnimatedBuilder(
                    animation: GameController.instance,
                    builder: (context, _) {
                      final c = GameController.instance;
                      final bool frozen = c.isGameOver || c.isPaused;
                      return IgnorePointer(
                        ignoring: frozen,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: c.isGameOver ? 0.0 : 1.0,
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              VirtualJoystick(),
                              Spacer(),
                              FlightControls(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 5. Pause menu
            AnimatedBuilder(
              animation: GameController.instance,
              builder: (context, _) {
                final c = GameController.instance;
                if (!c.isPaused || c.isGameOver) return const SizedBox.shrink();
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

            // 6. Game over
            AnimatedBuilder(
              animation: GameController.instance,
              builder: (context, _) {
                if (!GameController.instance.isGameOver) return const SizedBox.shrink();
                return GameOverScreen(onRetry: _restartGame, onHome: _quitToHome);
              },
            ),
          ],
        ),
      ),
    );
  }
}
