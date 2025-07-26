import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'registration_screen.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController companyNameController = TextEditingController();
  String? companySize;
  String? crmType;
  bool isLoading = false;
  bool _isHoveringHome = false;

  final List<String> companySizes = ['1-5', '6-25', '26-100+'];
  final List<String> crmTypes = ['Sales CRM', 'Marketing CRM', 'Support CRM'];

  bool get isFormComplete =>
      companyNameController.text.trim().isNotEmpty &&
      companySize != null &&
      crmType != null &&
      !isLoading;

  Future<void> submitOnboarding() async {
    if (!isFormComplete) return;
    setState(() => isLoading = true);

    try {
      final response = await ApiService().submitOnboarding(
        companySize!,
        crmType!,
        companyNameController.text.trim(),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response != null && response['company_id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('company_id', response['company_id']);
        await prefs.setString('crm_type', response['crm_type']);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company registered successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit. Please try again.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

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
        child: Column(
          children: [
            // App Bar with Home Button
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringHome = true),
                    onExit: (_) => setState(() => _isHoveringHome = false),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/', 
                          (route) => false
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isHoveringHome 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 28,
                              color: _isHoveringHome 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.8),
                            ),
                            if (!isSmallScreen) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Home',
                                style: TextStyle(
                                  color: _isHoveringHome 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'CRM Portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the row
                ],
              ),
            ),

            // Onboarding Form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: isSmallScreen ? screenWidth * 0.85 : 450,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tell us about your company',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 30),

                              _buildLabel('Company Name'),
                              _buildTextField(companyNameController, 'Enter your company name'),
                              const SizedBox(height: 30),

                              _buildLabel('How many people will use the CRM?'),
                              _buildDropdown(companySizes, companySize, (val) => setState(() => companySize = val)),
                              const SizedBox(height: 30),

                              _buildLabel('What type of CRM do you need?'),
                              _buildDropdown(crmTypes, crmType, (val) => setState(() => crmType = val)),
                              const SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isFormComplete ? submitOnboarding : null,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.pinkAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text, 
          style: const TextStyle(
            fontSize: 18, 
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint) => TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      );

  Widget _buildDropdown(List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        isExpanded: true,
        dropdownColor: Colors.black.withOpacity(0.8),
        value: value,
        underline: const SizedBox(),
        iconEnabledColor: Colors.white,
        hint: const Text('Select', style: TextStyle(color: Colors.white70)),
        style: const TextStyle(color: Colors.white),
        items: items.map((opt) =>
          DropdownMenuItem(
            value: opt, 
            child: Text(
              opt,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ).toList(),
        onChanged: onChanged,
      ),
    );
  }
}