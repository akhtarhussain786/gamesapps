import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce Portrait Orientation for 60fps mobile arcade feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Immersive Edge-to-Edge System Chrome
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const RoadsterRushApp());
}

class RoadsterRushApp extends StatelessWidget {
  const RoadsterRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROADSTER RUSH',
      debugShowCheckedModeBanner: false,
      theme: GameTheme.themeData,
      home: const SplashScreen(),
    );
  }
}

