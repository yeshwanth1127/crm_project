import 'package:flutter/material.dart';
import 'pages/landing_screen.dart';
import 'theme/app_theme.dart';
import 'pages/onboarding_screen.dart';

void main() {
  runApp(const MyCRMApp());
}

class MyCRMApp extends StatelessWidget {
  const MyCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Platform',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        // Other routes will be added here later:
        '/onboarding': (context) => const OnboardingScreen(),
        // '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
