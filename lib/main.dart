import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OpahApp());
}

class OpahApp extends StatelessWidget {
  const OpahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Opah',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFFB74D),        // Light orange
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFFFFCC80),
          onPrimaryContainer: const Color(0xFFBF360C),
          secondary: const Color(0xFF616161),     // Gray
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFE0E0E0),
          onSecondaryContainer: const Color(0xFF424242),
          surface: Colors.white,
          onSurface: const Color(0xFF212121),
          surfaceContainerHighest: const Color(0xFFF5F5F5),
          outline: const Color(0xFF9E9E9E),
          outlineVariant: const Color(0xFFE0E0E0),
        ),
        scaffoldBackgroundColor: Colors.white,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFB74D),
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.black,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.black,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFB74D),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
