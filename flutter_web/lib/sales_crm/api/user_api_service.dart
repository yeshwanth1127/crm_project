import 'dart:convert';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:flutter_web/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserApiService {
  static const baseUrl = ApiService.salesBaseUrl;

  // ✅ Fetch Users (http)
  static Future<List<dynamic>> fetchUsers(int companyId, {String? role}) async {
  try {
    final headers = await _getAuthHeaders();
    final query = role != null ? '?company_id=$companyId&role=$role' : '?company_id=$companyId';
    
    final response = await _handleRequest(
      http.get(
        Uri.parse('$baseUrl/list-users$query'),
        headers: headers,
      ),
    );
    
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
  static Future<List<Customer>> fetchCustomers(int companyId) async {
  final response = await http.get(Uri.parse('$baseUrl/customers/?company_id=$companyId'));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Customer.fromJson(json)).toList();  // ✅ Return proper Customer objects
  } else {
    throw Exception('Failed to fetch customers: ${response.body}');
  }
}


  // ✅ Create User
  static Future<dynamic> createUser(Map<String, dynamic> userData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/create-user'),
    headers: {
      'Content-Type': 'application/json',
    },
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
static Future<Map<String, int>> getCustomerStatusSummary(int companyId) async {
  final headers = await _getAuthHeaders();
  final uri = Uri.parse('$baseUrl/customers/status-summary').replace(queryParameters: {
    'company_id': companyId.toString(),
  });
  
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return Map<String, int>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to get customer status summary');
  }
}
  // ✅ Update Customer Status
  static Future<void> updateCustomerStatus(int customerId, String newStatus) async {
    final headers = await _getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/customers/update-status/$customerId'),
      headers: headers,
      body: jsonEncode({'new_status': newStatus}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer status');
    }
  }

  // ✅ Filter Customers by Status
static Future<List<dynamic>> getCustomersByStatus(int companyId, String status) async {
  final headers = await _getAuthHeaders();
  final uri = Uri.parse('$baseUrl/customers/filter-by-status').replace(queryParameters: {
    'company_id': companyId.toString(),
    'status': status,
  });
  
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to filter customers by status');
  }
}

  // ✅ Employee Status Summary
  static Future<Map<String, int>> getEmployeeStatusSummary(int companyId) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/employees/status-summary?company_id=$companyId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return Map<String, int>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get employee status summary');
    }
  }

 static Future<void> updateEmployeeStatus(int userId, String newStatus) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  if (token == null || token.isEmpty) {
    throw Exception("Authentication token is missing");
  }

  final uri = Uri.parse('$baseUrl/employees/update-status/$userId');

  final response = await http.patch(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'new_status': newStatus, // ✅ this must be non-null and non-empty
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update employee status:\n${response.body}');
  }
}


  // ✅ Reward Points Update
  static Future<void> updateEmployeeRewardPoints(int userId, int newPoints) async {
    final headers = await _getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/employees/update-rewards/$userId'),
      headers: headers,
      body: jsonEncode({'reward_points': newPoints}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update reward points');
    }
  }

  // ✅ Filter Employees by Status
static Future<List<dynamic>> getEmployeesByRoleAndStatus(int companyId, String role, {String? status}) async {
  final headers = await _getAuthHeaders();
  final queryParams = {
    'company_id': companyId.toString(),
    'role': role,
    if (status != null) 'status': status,
  };
  final uri = Uri.parse('$baseUrl/employees/by-role-status').replace(queryParameters: queryParams);
  
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to filter employees by role and status');
  }
}

static Future<List<dynamic>> getAuditLogs(int companyId, {DateTime? startDate, DateTime? endDate, String? action}) async {
  final headers = await _getAuthHeaders();
  final queryParams = {
    'company_id': companyId.toString(),
    if (startDate != null) 'start_date': startDate.toIso8601String(),
    if (endDate != null) 'end_date': endDate.toIso8601String(),
    if (action != null) 'action': action,
  };
  final uri = Uri.parse('$baseUrl/logs').replace(queryParameters: queryParams);
  
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to get audit logs');
  }
}
static Future<Map<String, String>> _getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token") ?? "";
  
  if (token.isEmpty) {
    throw Exception("Authentication token is missing - please login again");
  }
  
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
static Future<http.Response> _handleRequest(Future<http.Response> request) async {
  try {
    final response = await request;
    
    if (response.statusCode == 401) {
      // Token might be expired or invalid
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("token");
      throw Exception("Session expired - please login again");
    }
    
    return response;
  } catch (e) {
    if (e.toString().contains("401")) {
      throw Exception("Session expired - please login again");
    }
    rethrow;
  }
}
  static Future<int?> createCustomer(Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/customers/');
  final token = (await SharedPreferences.getInstance()).getString("token") ?? "";

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token';

  // Append fields
  data.forEach((key, value) {
    if (value != null) {
      request.fields[key] = value.toString();
    }
  });

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200 || response.statusCode == 201) {
    final decoded = jsonDecode(response.body);
    return decoded['customer_id'];
  } else {
    throw Exception("Customer creation failed: ${response.body}");
  }
}



  static Future<List<Map<String, dynamic>>> getCustomersOfSalesman(int salesmanId) async {
  final headers = await _getAuthHeaders();
  
  final response = await _handleRequest(
    http.get(
      Uri.parse('$baseUrl/salesman/$salesmanId/customers'),
      headers: headers,
    ),
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception("Failed to fetch assigned customers: ${response.body}");
  }
}

  static Future<List<Map<String, dynamic>>> getAllCustomers(int companyId) async {
    final uri = Uri.parse('$baseUrl/customers?company_id=$companyId');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to fetch customers");
    }
  }

  static Future<Map<String, dynamic>> getCustomerById(int customerId) async {
    final uri = Uri.parse('$baseUrl/customers/$customerId');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Customer not found");
    }
  }

  static Future<bool> updateCustomer(int customerId, Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/customers/$customerId');
  final headers = await _getAuthHeaders();

  final response = await http.put(
    uri,
    headers: {
      ...headers,
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  print("PUT $uri => ${response.statusCode}");
  print("Response body: ${response.body}");

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception("Failed to update customer: ${response.statusCode}");
  }
}


  static Future<void> saveCustomFieldValues(List<Map<String, dynamic>> values) async {
    final uri = Uri.parse('$baseUrl/custom-values/');
    final headers = await _getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(values),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to save custom field values");
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomFields(int companyId) async {
    final uri = Uri.parse('$baseUrl/custom-fields?company_id=$companyId');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to fetch custom fields");
    }
  }
static Future<void> saveCustomValues(List<Map<String, dynamic>> values) async {
  final uri = Uri.parse('$baseUrl/custom-values/');
  final headers = await _getAuthHeaders();

  final response = await http.post(
    uri,
    headers: {
      ...headers,
      'Content-Type': 'application/json',
    },
    body: jsonEncode(values),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to save custom field values");
  }
}

  static Future<bool> deleteCustomer(int id) async {
    final uri = Uri.parse('$baseUrl/customers/$id');
    final headers = await _getAuthHeaders();

    final response = await http.delete(uri, headers: headers);
    return response.statusCode == 200;
  }

  static Future<void> createCustomField(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/custom-fields/');
    final headers = await _getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create custom field");
    }
  }

  static Future<void> createLifecycleConfig(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/lifecycle-config/');
    final headers = await _getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create lifecycle config");
    }
  }

  static Future<List<Map<String, dynamic>>> getConversations(int customerId) async {
    final uri = Uri.parse('$baseUrl/conversations?customer_id=$customerId');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to load conversations");
    }
  }

  static Future<void> logConversation({
    required int customerId,
    required String channel,
    required String direction,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/conversations/');
    final headers = await _getAuthHeaders();

    final payload = {
      "customer_id": customerId,
      "channel": channel,
      "direction": direction,
      "message": message,
      "is_read": true,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to send conversation");
    }
  }

  static Future<List<Map<String, dynamic>>> getSalesmen(int companyId) async {
    final uri = Uri.parse('$baseUrl/list-users?company_id=$companyId&role=salesman');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to load salesmen");
    }
  }

  static Future<List<Map<String, dynamic>>> getLifecycleConfigs(int companyId) async {
    final uri = Uri.parse('$baseUrl/lifecycle-config/?company_id=$companyId');
    final headers = await _getAuthHeaders();

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to load lifecycle configs");
    }
  }
  static Future<List<Map<String, dynamic>>> getCustomerCustomFields(int companyId) async {
  final uri = Uri.parse('$baseUrl/custom-fields?company_id=$companyId');
  final headers = await _getAuthHeaders();

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception("Failed to load custom fields");
  }
}
static Future<void> logInteraction(Map<String, dynamic> data) async {
  final uri = Uri.parse('$baseUrl/interactions/create');
  final headers = await _getAuthHeaders(); // Add your auth header method

  final response = await http.post(
    uri,
    headers: {
      ...headers,
      'Content-Type': 'application/json',
    },
    body: json.encode(data),
  );

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to log interaction: ${response.body}');
  }
}

static Future<List<Map<String, dynamic>>> getInteractionsByCustomer(int customerId) async {
  final uri = Uri.parse('$baseUrl/interactions/by-customer/$customerId');
  final headers = await _getAuthHeaders();

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Failed to fetch interactions: ${response.body}');
  }
}
static Future<List<Map<String, dynamic>>> getUsersByRole(int companyId, String role) async {
  final uri = Uri.parse('$baseUrl/list-users?company_id=$companyId&role=$role');
  final headers = await _getAuthHeaders();

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Failed to load users by role: ${response.body}');
  }
}
static Future<List<Map<String, dynamic>>> getCustomersByCompany(int companyId) async {
  final uri = Uri.parse('$baseUrl/customers?company_id=$companyId');
  final headers = await _getAuthHeaders();

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Failed to load customers: ${response.body}');
  }
}
static Future<List<Map<String, dynamic>>> getCustomersBySalesman(int salesmanId) async {
  final uri = Uri.parse('$baseUrl/salesman/$salesmanId/customers');
  final headers = await _getAuthHeaders();

  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Failed to load customers by salesman: ${response.body}');
  }
}
static Future<int> getCompanyId() async {
  final prefs = await SharedPreferences.getInstance();
  final companyId = prefs.getInt('company_id');
  if (companyId == null) throw Exception('Company ID not found in session');
  return companyId;
}
// 1. Get all task types
  static Future<List<TaskType>> fetchTaskTypes() async {
    final response = await http.get(Uri.parse("$baseUrl/task-types/"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TaskType.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load task types");
    }
  }

  // 2. Assign a task
  static Future<bool> assignTask(TaskAssignmentCreate task) async {
    final response = await http.post(
      Uri.parse("$baseUrl/assign-task/"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(task.toJson()),
    );
    return response.statusCode == 200;
  }

  // 3. Get all assigned tasks for a company (optionally filter by status)
  static Future<List<TaskAssignment>> fetchTasksByCompany(int companyId) async {
  final response = await http.get(Uri.parse("$baseUrl/tasks/by-company/$companyId"));

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => TaskAssignment.fromJson(json)).toList();
  } else {
    throw Exception("Failed to load tasks");
  }
}




  // 4. Get tasks assigned to a specific user
  static Future<List<TaskAssignment>> fetchTasksByUser({
    required int userId,
    String? status,
  }) async {
    final uri = Uri.parse("$baseUrl/tasks/user/$userId")
        .replace(queryParameters: {
          if (status != null) 'status': status,
        });

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TaskAssignment.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load user tasks");
    }
  }

  // 5. Mark a task as completed
  static Future<bool> markTaskAsCompleted(String taskId) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/tasks/complete/$taskId"),
    );
    return response.statusCode == 200;
  }

  // 6. Get task logs
  static Future<List<TaskLog>> fetchTaskLogs({required int companyId}) async {
    final uri = Uri.parse("$baseUrl/tasks/logs/")
        .replace(queryParameters: {'company_id': companyId.toString()});

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => TaskLog.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load task logs");
    }
  }

  // 7. Get all team leaders + salesmen (user selection)
  static Future<List<User>> fetchSalesAndTeamUsers(int companyId) async {
    final uri = Uri.parse("$baseUrl/list-users")
        .replace(queryParameters: {'company_id': companyId.toString()});

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((json) => User.fromJson(json))
          .where((u) => u.role == 'salesman' || u.role == 'team_leader')
          .toList();
    } else {
      throw Exception("Failed to load users");
    }
  }
  static Future<bool> initializeTaskTypes() async {
  final response = await http.post(Uri.parse("$baseUrl/init-task-types/"));
  return response.statusCode == 200;
}
static Future<List<Customer>> fetchCustomersByCompany(int companyId) async {
  final response = await http.get(Uri.parse("$baseUrl/customers/by-company/$companyId"));
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((json) => Customer.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load customers');
  }
}
static Future<int> getTeamLeaderIdByEmail(String email, String token, int companyId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/list-users?company_id=$companyId&role=team_leader'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final users = json.decode(response.body);
    final user = users.firstWhere(
      (u) => u['email'].toLowerCase() == email.toLowerCase(),
      orElse: () => null,
    );
    if (user == null) throw Exception('Team Leader with this email not found.');
    return user['id'];
  } else {
    throw Exception('Failed to fetch Team Leader ID');
  }
}


static Future<Map<String, dynamic>> getTeamLeaderOverview(int teamLeaderId, String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/team-leader/$teamLeaderId/overview'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load dashboard data');
  }
}
static Future<Map<String, dynamic>> fetchSalesmanOverview(int salesmanId) async {
    final url = Uri.parse('$baseUrl/salesman/overview/$salesmanId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load overview: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching salesman overview: $e');
    }
  }
  static Future<List<dynamic>> fetchAssignedCustomers(int salesmanId) async {
  final response = await http.get(Uri.parse('$baseUrl/customers/assigned/$salesmanId'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load assigned customers');
  }
}
static Future<List<dynamic>> fetchPendingTasks(int salesmanId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/tasks/assigned/$salesmanId'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch tasks');
  }
}

}

