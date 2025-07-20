import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to CRM Platform'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
  Navigator.pushNamed(context, '/onboarding');
},

          child: const Text('Get Started'),
        ),
      ),
    );
  }
}
