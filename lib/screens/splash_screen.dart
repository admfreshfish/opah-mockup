import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;
    final repo = ProfileRepository.instance;
    final isLoggedIn = await repo.isLoggedIn();
    if (!mounted) return;
    if (!isLoggedIn) {
      _goToLogin();
      return;
    }
    final profileComplete = await repo.isProfileComplete();
    if (!mounted) return;
    if (!profileComplete) {
      _goToProfileRequired();
    } else {
      _goToHome();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _goToProfileRequired() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const ProfileScreen(required: true),
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Opah',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
