# 🏎️ ROADSTER RUSH

A high-octane, portrait pseudo-3D mobile arcade game running at a fluid 60 FPS, built with **Flutter** and the **Flame Engine**. 

> **Non-Commercial Fan Project**: Features a generic futuristic electric roadster silhouette with zero brand logos or trademarks.

---

## 🎮 Gameplay & Mechanics

- **Auto-Cruise Acceleration**: The electric roadster accelerates forward along a winding pseudo-3D highway. Forward speed increases with each level.
- **Virtual Joystick (Left Side)**:
  - **Steering**: Move left/right to weave through lanes with real-time camera banking and vehicle roll.
  - **Nose / Pitch Control**: When airborne, tilt forward to dive or backward to climb/glide.
- **Flight Thrusters & AIR Meter (Bottom-Right)**:
  - **Big "FLY" Button**: Hold to ignite dual twin plasma thrusters, lifting the car into the air to fly clean over obstacle piles.
  - **AIR Meter**: Depletes while airborne (indicated by the neon cyan circular gauge); refills automatically when driving on asphalt.
- **Stunt Flip Button (Yellow)**:
  - While airborne, tap the **FLIP** button to perform a 360° stunt backflip for **+500 BONUS POINTS**!
- **Traffic Piles & Overpass System**:
  - Piles of parked, abandoned, and stacked cars (in white, blue, red, and black) obstruct lanes.
  - Colliding on the ground triggers a crash with slow-motion and screen shake.
  - Flying high enough allows you to pass safely overhead with an **OVERPASS BONUS (+200)**.
- **Dynamic Landing Zone Indicator**:
  - When airborne, a predictive targeting ring projects onto the road surface ahead.
  - **Green Ring**: Projected touchdown is in a safe open gap. Touching down earns a **LANDING BONUS (+300)**.
  - **Red Ring**: Projected touchdown overlaps a vehicle stack or goes off-road. Landing here causes a crash!
- **Tactical Status Chips**:
  - Live HUD alerts below the stats panel: `"STACK AHEAD 25M"`, `"HOLD FLY"`, `"LANDING GOOD"`, `"NOSE DOWN"`, etc.
- **Levels & Gantries**:
  - Every 500 meters, cross under an illuminated finish-line gantry with stadium lights, unlocking the next level with higher speed and denser traffic.

---

## 🎨 Visual Style

- **100% Procedural Vector Graphics**: No external images, sprites, or textures are required! All visuals are drawn directly with Flutter Canvas and vector paths for ultra-crisp resolution on any display.
- **Low-Poly / Voxel City Skyline**: Multi-layered parallax skyscrapers in blue, orange, and steel grey tones with glowing windows and flashing beacon spires.
- **Pseudo-3D Perspective Road**: Vanishing point at the horizon with projected depth scaling, alternating red/white rumble curbs, dark asphalt, emerald grass verges, and spectator grandstands full of animated pixel crowd.
- **Cyberpunk UI**: Neon cyan/aqua accents, dark translucent glassmorphism panels, and monospace LCD figures.

---

## 📁 Project Architecture

```
d:\GAME APP BUILD\
├── lib/
│   ├── main.dart                      # Orientation lock & app entrypoint
│   ├── core/
│   │   ├── constants.dart             # World geometry, physics & scoring constants
│   │   ├── theme.dart                 # Cyberpunk palette, glass panels & LCD styles
│   │   ├── audio_manager.dart         # Engine simulation, SFX chimes & haptics
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
│   │       ├── player_car.dart        # Vector roadster, plasma thrusters & flips
│   │       ├── traffic_cluster.dart   # Object-pooled obstacle clusters
│   │       ├── landing_target.dart    # Real-time predictive landing reticle
│   │       └── particles.dart         # Object-pooled thruster sparks & debris
│   └── widgets/
│       ├── hud_overlay.dart           # LCD score, level, progress bar & pause
│       ├── virtual_joystick.dart      # Left thumb steering & pitch control
│       ├── flight_controls.dart       # FLY button with AIR ring & FLIP button
│       ├── status_chips_overlay.dart  # Tactical alert chips with colored dots
│       └── pause_dialog.dart          # Glassmorphism pause menu
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

### 2. Run the Game
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

