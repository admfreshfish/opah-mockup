import 'dart:io';

import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static bool get _isAppleDevice =>
      Platform.isIOS || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.photo_library_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Opah',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share moments from your events',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              if (_isAppleDevice) ...[
                _SignInButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  onPressed: () => _handleSignIn(context, 'Apple'),
                ),
                const SizedBox(height: 12),
              ],
              _SignInButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                onPressed: () => _handleSignIn(context, 'Google'),
              ),
              const SizedBox(height: 12),
              _SignInButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                onPressed: () => _handleSignIn(context, 'Facebook'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context, String provider) async {
    await ProfileRepository.instance.setLoggedIn(true);
    if (!context.mounted) return;
    final profileComplete = await ProfileRepository.instance.isProfileComplete();
    if (!context.mounted) return;
    if (!profileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const ProfileScreen(required: true),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}
