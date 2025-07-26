import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

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
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20.0 : 40.0,
              vertical: 30.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context, screenWidth),
                const SizedBox(height: 50),
                _buildMainContent(context, screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Image.asset(
                'assets/images/orbitcrm_logo.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (!isSmallScreen(screenWidth))
            Row(
              children: [
                _NavItem(title: 'Home', isActive: true),
                _NavItem(title: 'About'),
                _NavItem(title: 'Features'),
                _NavItem(title: 'Implementation'),
                _NavItem(title: 'Contact'),
                const SizedBox(width: 30),
                _buildSignInButton(context),
              ],
            ),
          if (isSmallScreen(screenWidth))
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                // TODO: Implement mobile menu drawer
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth) {
    final isWideScreen = screenWidth > 900;
    final headingSize = isWideScreen ? 70.0 : min(screenWidth * 0.12, 45.0);
    final descriptionSize = isWideScreen ? 18.0 : 16.0;

    return Flex(
      direction: isWideScreen ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: isWideScreen ? 5 : 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: isWideScreen ? 0 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Orbit',
                    style: TextStyle(
                      fontSize: headingSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'CRM',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transform your customer relationships with our powerful all-in-one CRM platform. '
                  'Streamline sales, marketing, and support in one seamless solution.',
                  style: TextStyle(
                    fontSize: descriptionSize,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _buildActionButtons(context, screenWidth),
                const SizedBox(height: 30),
              ],
            ),
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
  }

  Widget _buildActionButtons(BuildContext context, double screenWidth) {
    final isSmall = screenWidth < 400;

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 30,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/onboarding'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 30,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
          child: Text(
            'Register',
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/onboarding'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 30,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Get Demo',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSignInButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/login'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  bool isSmallScreen(double screenWidth) => screenWidth < 700;
}

class _NavItem extends StatelessWidget {
  final String title;
  final bool isActive;
  
  const _NavItem({
    required this.title,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: Colors.pinkAccent,
              ),
          ],
        ),
      ),
    );
  }
}