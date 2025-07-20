import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000/api/onboarding/'; // change to your backend IP when deployed

Future<bool> submitOnboarding(String companySize, String crmType, String companyName) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/onboarding/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "company_name": companyName,
        "company_size": companySize,
        "crm_type": crmType,
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to submit onboarding. Backend responded with ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error during onboarding API call: $e');
    return false;
  }
}


}
