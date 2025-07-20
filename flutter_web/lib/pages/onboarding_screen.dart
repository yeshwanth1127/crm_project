import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    setState(() => isLoading = true);
    final success = await ApiService().submitOnboarding(
      companySize!,
      crmType!,
      companyNameController.text.trim(),
    );
    setState(() => isLoading = false);

    if (success) {
      Navigator.pushNamed(context, '/register');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit. Please try again.")),
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
