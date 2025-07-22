import 'dart:convert';
import 'package:http/http.dart' as http;

/// ✅ Adjust your baseUrl based on your testing environment:
/// For Web → 'http://127.0.0.1:8000'
/// For Android Emulator → 'http://10.0.2.2:8000'
/// For physical device → 'http://<your_local_ip>:8000'

class ApiService {
  static const String salesBaseUrl = 'http://192.168.0.14:8000/api/sales';
  static const String baseUrl = 'http://192.168.0.14:8000/api/onboarding';

  Future<Map<String, dynamic>?> submitOnboarding(String companySize, String crmType, String companyName) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "company_name": companyName,
          "company_size": companySize,
          "crm_type": crmType.toLowerCase().replaceAll(' ', '_'),
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('❗️ Backend error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❗️ Network/Unexpected Error: $e');
      return null;
    }
  }
  static Future<Map<String, dynamic>> fetchDashboardStats(int companyId, String range) async {
    final response = await http.get(
  Uri.parse('http://192.168.0.14:8000/api/sales/analytics/overview/?company_id=$companyId&range=$range')
);
    if (response.statusCode != 200) throw Exception('Failed to load dashboard stats');
    return json.decode(response.body);
  }

  static Future<List<String>> fetchSelectedFeatures(int companyId) async {
final response = await http.get(
  Uri.parse('http://192.168.0.14:8000/api/sales/get-features?company_id=$companyId')
);
    if (response.statusCode != 200) throw Exception('Failed to load features');
    final data = json.decode(response.body);
    return List<String>.from(data['selected_features']);
  }

  static Future<void> saveFeatures(int companyId, List<String> features) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/update-features'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'company_id': companyId, 'updated_features': features}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update features');
  }
}
