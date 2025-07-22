import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavBar(context, screenWidth),
                const SizedBox(height: 50),

                LayoutBuilder(builder: (context, constraints) {
                  bool isWideScreen = constraints.maxWidth > 900;
                  return Flex(
                    direction: isWideScreen ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isWideScreen ? 5 : 0,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isWideScreen ? 0 : 30),
                          child: _TextWithButtons(context, screenWidth),
                        ),
                      ),
                      if (isWideScreen) const SizedBox(width: 40),
                      if (isWideScreen)
                        Expanded(
                          flex: 5,
                          child: Lottie.asset(
                            'assets/animations/landing_page.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (!isWideScreen)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Lottie.asset(
                            'assets/animations/landing_page.json',
                            width: min(screenWidth * 0.9, 400),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
  'assets/images/orbitcrm_logo.png',
  height: 50, // adjust as needed
),
        if (screenWidth > 700)
          Row(
            children: [
              _NavItem(title: 'Home'),
              _NavItem(title: 'About'),
              _NavItem(title: 'Features'),
              _NavItem(title: 'Implementation'),
              _NavItem(title: 'Contact'),
              const SizedBox(width: 20),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  'Sign In',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _TextWithButtons(BuildContext context, double screenWidth) {
    double headingSize = screenWidth > 700 ? 70 : 45;
    double descriptionSize = screenWidth > 700 ? 18 : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRM',
          style: TextStyle(
            fontSize: headingSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Manage your sales, leads, and customers with ease.\nYour all-in-one CRM platform awaits.',
          style: TextStyle(
            fontSize: descriptionSize,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/onboarding'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Register'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/onboarding'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  const _NavItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
