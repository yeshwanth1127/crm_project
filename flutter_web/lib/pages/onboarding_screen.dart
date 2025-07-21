import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'registration_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? companySize;
  String? crmType;
  bool isLoading = false;
  final TextEditingController companyNameController = TextEditingController();

  final List<String> companySizes = ['1-5', '6-25', '26-100+'];
  final List<String> crmTypes = ['Sales CRM', 'Marketing CRM', 'Support CRM'];

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
        prefs.setInt('company_id', response['company_id']);
        prefs.setString('crm_type', response['crm_type']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company registered successfully!")),
        );

        if (!mounted) return;
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

  bool get isFormComplete =>
      companySize != null &&
      crmType != null &&
      companyNameController.text.trim().isNotEmpty &&
      !isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Company Name', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: companyNameController,
              decoration: const InputDecoration(
                hintText: 'Enter your company name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            const Text('How many people will use the CRM?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: companySize,
              hint: const Text('Select Company Size'),
              items: companySizes.map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
              onChanged: (value) => setState(() => companySize = value),
            ),
            const SizedBox(height: 30),
            const Text('What type of CRM do you need?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: crmType,
              hint: const Text('Select CRM Type'),
              items: crmTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (value) => setState(() => crmType = value),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormComplete ? submitOnboarding : null,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
