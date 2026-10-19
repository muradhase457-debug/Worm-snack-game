import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // If the workflow did not generate real Firebase keys, show a friendly
  // setup screen instead of crashing.
  if (DefaultFirebaseOptions.needsSetup) {
    runApp(const SetupNeededApp());
    return;
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WormSnakeApp());
}

/// Shown when google-services.json was not added to the repo root.
class SetupNeededApp extends StatelessWidget {
  const SetupNeededApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🐛', style: TextStyle(fontSize: 64)),
                SizedBox(height: 12),
                Text(
                  'Setup Needed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'google-services.json repo root e add koro,\n'
                  'tarpor Actions theke abar build dao.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WormSnakeApp extends StatelessWidget {
  const WormSnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worm Snake Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/home': (context) => const HomeScreen(),
        '/game': (context) => const GameScreen(),
        '/wardrobe': (context) => const WardrobeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/admin': (context) => const AdminGate(),
      },
    );
  }
}

/// Decides Login vs Home, and blocks banned accounts.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        return FutureBuilder<bool>(
          future: AuthService.isBanned(user.uid),
          builder: (ctx, b) {
            if (b.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (b.data == true) return const BannedScreen();
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚫', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                'This account is banned.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await AuthService.signOut();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Admin route guard - only the admin email ever sees AdminScreen.
/// Normal users are sent to Home instead.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isAdmin) return const HomeScreen();
    return const AdminScreen();
  }
}
