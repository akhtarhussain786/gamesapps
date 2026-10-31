# 🏎️ ROADSTER RUSH

A high-octane, portrait pseudo-3D mobile arcade game running at a fluid 60 FPS, built with **Flutter** and the **Flame Engine**. 

> **Non-Commercial Fan Project**: Features a generic futuristic electric roadster silhouette with zero brand logos or trademarks.

---

## 🎮 Gameplay & Mechanics

- **Hold to Drive**: Keep any finger on the screen to accelerate; let go and the roadster brakes to a stop. Top speed rises with each level.
- **Steer Pad (Left Thumb)**: Slide left/right to change lanes. The car rolls into the turn and shows a sliver of its flank.
- **FLY Button & AIR Gauge (Bottom-Right)**:
  - **Hold FLY** to fire the twin plasma thrusters in the rear diffuser and lift off.
  - The **AIR** ring around the button drains while flying and refills on the road. It turns red when low.
  - When a pile in your lane needs clearing *now*, the button pulses red and the HUD shows **FLY NOW!**
- **FLIP Button (Magenta)**: While airborne, tap for a 360° backflip. **+50** points when the rotation completes; landing mid-flip earns nothing.
- **Traffic Piles**:
  - Abandoned cars (white, blue, red, black) block one or two lanes. Higher levels stack them up to three high, and every raised car sits on another car.
  - Touching a pile ends the run (slow-motion crash and screen shake).
  - Fly above the top of a pile for **+200 per car** cleared.
- **Landing Reticle**: While airborne, a ring on the road shows where you would touch down if you released FLY now.
  - **Green**: clear road. **Red**: a pile is there, so keep flying.
  - A touchdown after clearing at least one pile earns a **CLEAN LANDING +300**.
- **HUD Feedback**:
  - One alert chip below the HUD for warnings (`PILE AHEAD 86M · 2 HIGH`, `FLY NOW!`, `HAZARD BELOW · HOLD FLY`, `AIR DEPLETED`). A more urgent alert is never hidden by a less urgent one.
  - Rewards (`+200 OVERPASS`, `+50 FLIP`, `LEVEL 2 · SPEED UP`) float up from above the car, separately from warnings.
- **Levels & Gantries**: Every 500 m you pass under a finish-line gantry and move up a level with more speed and denser traffic.
- **Auto-pause**: The game pauses itself when the app is backgrounded.

---

## 🎨 Visual Style

- **Procedural Vector Graphics**: No images, sprites or textures. Everything is drawn with Flutter Canvas paths, so it stays crisp on any display.
- **Player Roadster**: A low, wide magenta electric roadster with visible tyres, a tinted canopy, twin fairings, a GT wing, a full-width LED light bar and glowing thruster nozzles. Traffic is deliberately plain boxy sedans, so your car is always easy to spot.
- **Pseudo-3D Road**: OutRun-style projection with rumble curbs, grandstands and a parallax city skyline. The player car is placed using the same projection as the road and traffic, so what you see is what collides.
- **UI**: Bundled fonts (Russo One for headings, Rajdhani for labels, Share Tech Mono for numbers) look the same on every platform. Each colour has one meaning: cyan = systems/info, magenta = your car & stunts, amber = caution, red = danger, green = rewards.

---

## 📁 Project Architecture

```
gamesapps/
├── lib/
│   ├── main.dart                      # Orientation lock & app entrypoint
│   ├── core/
│   │   ├── constants.dart             # World geometry, physics & scoring constants
│   │   ├── theme.dart                 # Cyberpunk palette, glass panels & LCD styles
│   │   ├── audio_manager.dart         # SFX & haptics (respects the sound toggle)
│   │   └── game_state.dart            # Reactive ValueNotifier-driven game controller
│   ├── screens/
│   │   ├── splash_screen.dart         # Radial glow, 12-block loader & start prompt
│   │   ├── game_screen.dart           # FlameGame host with HUD & control overlays
│   │   └── game_over_screen.dart      # Crash forensic report, scores & retry
│   ├── game/
│   │   ├── roadster_game.dart         # 60fps loop, camera tilt, shake & collisions
│   │   └── components/
│   │       ├── skyline_horizon.dart   # Voxel city horizon & twilight gradient
│   │       ├── road_mesh.dart         # Pseudo-3D curved road & finish gantries
│   │       ├── player_car.dart        # Player pose, shadow, roll, thrusters & flips
│   │       ├── roadster_painter.dart  # Vector artwork for the player's roadster
│   │       ├── car_renderer.dart      # Rear-view traffic sedan
│   │       ├── traffic_cluster.dart   # Stacked traffic piles & hit tests
│   │       ├── landing_target.dart    # Real-time predictive landing reticle
│   │       └── particles.dart         # Object-pooled thruster sparks & debris
│   └── widgets/
│       ├── hud_overlay.dart           # Score, level progress, distance, speed & pause
│       ├── virtual_joystick.dart      # Left-thumb horizontal steer pad
│       ├── flight_controls.dart       # FLY button with AIR ring & FLIP button
│       ├── status_chips_overlay.dart  # Prioritised alert chip
│       ├── score_popups_overlay.dart  # Floating reward popups
│       └── pause_dialog.dart          # Glassmorphism pause menu
├── assets/fonts/                      # Bundled OFL fonts + licences
├── test/game_logic_test.dart          # Logic tests (bonuses, piles, hit boxes, projection)
├── pubspec.yaml                       # Dependencies: flame, flame_audio, shared_preferences
└── README.md
```

---

## 🚀 How to Run

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (version `>=3.10.0`).

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the Tests
```bash
flutter test
```

### 3. Run the Game
- **Android Device / Emulator**:
  ```bash
  flutter run -d android
  ```
- **Chrome / Web Browser**:
  ```bash
  flutter run -d chrome
  ```
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **iOS Simulator / Device**:
  ```bash
  flutter run -d ios
  ```

---

## ⚡ Performance Optimizations

1. **Object Pooling**: Obstacle car clusters and particle systems are pre-allocated and recycled to prevent garbage collection frame drops.
2. **Zero-Per-Frame Allocations**: Math matrices, projections, and vectors reuse cached instances.
3. **Hardware-Accelerated Vector Canvas**: High framerate vector rendering across mobile GPUs.

