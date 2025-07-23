import 'dart:convert';
import 'package:flutter_web/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class UserApiService {
  static const baseUrl = ApiService.salesBaseUrl;
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://192.168.0.137:8000/api/sales'));

  // ✅ Fetch Users (http)
  static Future<List<dynamic>> fetchUsers(int companyId, {String? role}) async {
    try {
      final query = role != null ? '?company_id=$companyId&role=$role' : '?company_id=$companyId';
      final response = await http.get(Uri.parse('$baseUrl/list-users$query'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch users: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // ✅ Fetch Customers
  static Future<List<dynamic>> fetchCustomers(int companyId) async {
    final response = await http.get(Uri.parse('$baseUrl/customers/?company_id=$companyId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch customers: ${response.body}');
    }
  }

  // ✅ Create User
  static Future<dynamic> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  // ✅ Delete User
  static Future<bool> deleteUser(int userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/delete-user/$userId'));
    if (response.statusCode == 200) return true;
    throw Exception('Failed to delete user: ${response.body}');
  }

  // ✅ Change Role
  static Future<void> changeUserRole(int userId, String newRole) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/change-role/$userId'),
      body: {'new_role': newRole},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change role: ${response.body}');
    }
  }

  // ✅ Assign Salesman to Team Leader
  static Future<void> assignSalesmanToTeamLeader(int salesmanId, int teamLeaderId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/assign-team-leader'),
      body: {
        'salesman_id': salesmanId.toString(),
        'team_leader_id': teamLeaderId.toString(),
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign salesman: ${response.body}');
    }
  }

  // ✅ Hierarchy
  static Future<List<dynamic>> fetchHierarchy(int companyId) async {
    final response = await http.get(Uri.parse('$baseUrl/get-hierarchy?company_id=$companyId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['team_leaders'];
    } else {
      throw Exception('Failed to fetch hierarchy');
    }
  }

  // ✅ Assign Customers by Criteria
  static Future<void> assignCustomersByCriteria(
      int salesmanId, {String? pipelineStage, String? leadStatus}) async {
    final body = {
      'salesman_id': salesmanId.toString(),
      if (pipelineStage != null) 'pipeline_stage': pipelineStage,
      if (leadStatus != null) 'lead_status': leadStatus,
    };
    final response = await http.patch(
      Uri.parse('$baseUrl/assign-customers-criteria'),
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign customers: ${response.body}');
    }
  }

  // ✅ ✅ ✅ Account Status Section ✅ ✅ ✅

  // ✅ Customer Status Summary
  Future<Map<String, int>> getCustomerStatusSummary(int companyId) async {
    final response = await dio.get('/customers/status-summary', queryParameters: {'company_id': companyId});
    return Map<String, int>.from(response.data as Map);
  }

  // ✅ Update Customer Status
  Future<void> updateCustomerStatus(int customerId, String newStatus) async {
    await dio.patch('/customers/update-status/$customerId',
      data: FormData.fromMap({'new_status': newStatus}),
    );
  }

  // ✅ Filter Customers by Status
  Future<List<dynamic>> getCustomersByStatus(int companyId, String status) async {
    final response = await dio.get('/customers/filter-by-status', queryParameters: {
      'company_id': companyId,
      'status': status,
    });
    return response.data as List<dynamic>;
  }

  // ✅ Employee Status Summary
  Future<Map<String, int>> getEmployeeStatusSummary(int companyId) async {
    final response = await dio.get('/employees/status-summary', queryParameters: {'company_id': companyId});
    return Map<String, int>.from(response.data as Map);
  }

  // ✅ Update Employee Status
  Future<void> updateEmployeeStatus(int userId, String newStatus) async {
    await dio.patch('/employees/update-status/$userId',
      data: FormData.fromMap({'new_status': newStatus}),
    );
  }

  // ✅ Reward Points Update
  Future<void> updateEmployeeRewardPoints(int userId, int newPoints) async {
    await dio.patch('/employees/update-rewards/$userId',
      data: FormData.fromMap({'reward_points': newPoints}),
    );
  }

  // ✅ Filter Employees by Status
  Future<List<dynamic>> getEmployeesByRoleAndStatus(int companyId, String role, {String? status}) async {
    final query = {
      'company_id': companyId,
      'role': role,
      if (status != null) 'status': status,
    };
    final response = await dio.get('/employees/by-role-status', queryParameters: query);
    return response.data as List<dynamic>;
  }
   Future<List<dynamic>> getAuditLogs(int companyId, {DateTime? startDate, DateTime? endDate, String? action}) async {
  // Build query
  String url = '$baseUrl/logs?company_id=$companyId';
  if (startDate != null) url += '&start_date=${startDate.toIso8601String()}';
  if (endDate != null) url += '&end_date=${endDate.toIso8601String()}';
  if (action != null) url += '&action=$action';
  final response = await http.get(Uri.parse(url));
  return jsonDecode(response.body);
}

}

