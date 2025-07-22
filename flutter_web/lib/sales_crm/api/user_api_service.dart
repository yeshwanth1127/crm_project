import 'dart:convert';
import 'package:flutter_web/services/api_service.dart';
import 'package:http/http.dart' as http;


class UserApiService {
  static const  baseUrl = ApiService.salesBaseUrl;


  static Future<List<dynamic>> fetchUsers(int companyId, {String? role}) async {
    try {
      final query = role != null ? '?company_id=$companyId&role=$role' : '?company_id=$companyId';
      final response = await http.get(Uri.parse('$baseUrl/list-users$query'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Error fetching users: \$e');
    }
  }

  static Future<dynamic> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create user: \${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating user: \$e');
    }
  }

  static Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/delete-user/\$userId'));
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: \$e');
    }
  }
} 
