import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserApiService userApi = UserApiService();
  List<dynamic> hierarchyData = [];
  List<dynamic> salesmanListForCustomer = [];
  bool expandRole = false;
  bool expandSalesman = false;
  bool expandCustomerCriteria = false;
  dynamic selectedUserForRoleChange;
  String? selectedNewRole;
  dynamic selectedSalesman;
  dynamic selectedTeamLeader;
  dynamic selectedSalesmanForCustomer;
  String? selectedPipelineStage;
  String? selectedLeadStatus;
  String? selectedRole;
  String selectedUserPage = 'User List';
  String accountTab = 'customer';
  List<dynamic> employeeList = [];
  Map<String, int> employeeStatusSummary = {};
  String? selectedEmployeeStatus;
  bool isEmployeeLoading = false;
  int? selectedEmployeeRewardUpdate;
  String? selectedNewEmployeeStatus;
  String? selectedCustomerStatus;
  List<dynamic> filteredCustomers = [];
  bool isCustomerLoading = false;
  int? companyId;
  List<dynamic> userList = [];
  List<dynamic> salesmanList = [];
  List<dynamic> teamLeaderList = [];
  List<dynamic> customerList = [];
  List<String> pipelineStages = ['Prospecting', 'Qualified', 'Negotiation'];
  List<String> leadStatuses = ['lead', 'client'];
  List<dynamic> auditLogs = [];
  bool isAuditLoading = false;
  DateTime? startDate, endDate;
  String? selectedActionType;
  List<String> actionTypes = ['Created Customer', 'Updated Customer', 'Deleted Customer', 'Created Task', 'Updated User Role', 'Assigned Salesman', 'Updated Company Settings'];


  bool isLoading = true;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    loadCompanyIdAndFetchUsers();
    fetchHierarchy();
  }

  Future<void> loadCompanyIdAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    companyId = prefs.getInt('company_id');
    if (companyId != null) {
      await fetchUsers();
      await fetchSalesmen();
      await fetchSalesmenForCustomer();
      await fetchTeamLeaders();
      await fetchCustomers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Company ID not found')));
    }
  }
Future<void> fetchAuditLogs() async {
  if (companyId == null) return;
  setState(() => isAuditLoading = true);
  try {
    auditLogs = await UserApiService.getAuditLogs(companyId!,
        startDate: startDate, endDate: endDate, action: selectedActionType);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load audit logs')));
  }
  setState(() => isAuditLoading = false);
}
Widget _buildAuditLogsPage() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const Text('Audit Logs', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildAuditFilters(),
        const SizedBox(height: 10),
        Expanded(
          child: isAuditLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView.builder(
                  itemCount: auditLogs.length,
                  itemBuilder: (context, index) => _buildAuditLogTile(auditLogs[index]),
                ),
        ),
      ],
    ),
  );
}
Widget _buildAuditFilters() {
  return Wrap(
    spacing: 10,
    children: [
      ElevatedButton(
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              startDate = picked.start;
              endDate = picked.end;
            });
            fetchAuditLogs();
          }
        },
        child: const Text('Select Date Range'),
      ),
      DropdownButton<String>(
        hint: const Text('Select Action', style: TextStyle(color: Colors.white)),
        value: selectedActionType,
        dropdownColor: Colors.blueGrey,
        items: actionTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) {
          setState(() => selectedActionType = value);
          fetchAuditLogs();
        },
      ),
      ElevatedButton(
        onPressed: () {
          setState(() {
            startDate = null;
            endDate = null;
            selectedActionType = null;
          });
          fetchAuditLogs();
        },
        child: const Text('Clear Filters'),
      ),
    ],
  );
}
Widget _buildAuditLogTile(dynamic log) {
  return Card(
    color: Colors.white.withOpacity(0.9),
    child: ExpansionTile(
      title: Text('${log['action']} by User ID: ${log['user_id']}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('At ${log['timestamp']}'),
      children: [
        if (log['before_data'] != null) ListTile(
          title: const Text('Before Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(log['before_data'].toString()),
        ),
        if (log['after_data'] != null) ListTile(
          title: const Text('After Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(log['after_data'].toString()),
        ),
      ],
    ),
  );
}

  Widget _navButton(String title) {
    final isSelected = selectedUserPage == title;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.2),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => selectedUserPage = title);
      },
    );
  }

  Future<void> fetchUsers() async {
    if (companyId == null) return;
    setState(() => isLoading = true);
    try {
      userList = await UserApiService.fetchUsers(companyId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load users')));
    }
    setState(() => isLoading = false);
  }

  Future<void> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required int companyId,
  }) async {
    final userData = {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'company_id': companyId,
    };
    try {
      await UserApiService.createUser(userData);
      fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create user')));
    }
  }

  Future<void> fetchHierarchy() async {
    if (companyId == null) return;
    try {
      hierarchyData = await UserApiService.fetchHierarchy(companyId!);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load hierarchy'))
      );
    }
  }

  Future<void> fetchSalesmen() async {
    if (companyId == null) return;
    try {
      List<dynamic> allSalesmen = await UserApiService.fetchUsers(companyId!, role: 'salesman');
      salesmanList = allSalesmen.where((user) => user['assigned_team_leader'] == null).toList();
      setState(() {
        selectedSalesman = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load salesmen'))
      );
    }
  }

  Future<void> fetchSalesmenForCustomer() async {
    if (companyId == null) return;
    try {
      salesmanListForCustomer = await UserApiService.fetchUsers(companyId!, role: 'salesman');
      setState(() {
        selectedSalesmanForCustomer = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load salesmen for customer assignment'))
      );
    }
  }

  Future<void> fetchTeamLeaders() async {
    if (companyId == null) return;
    try {
      teamLeaderList = await UserApiService.fetchUsers(companyId!, role: 'team_leader');
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load team leaders')));
    }
  }

  Future<void> fetchCustomers() async {
    try {
      customerList = await UserApiService.fetchCustomers(companyId!);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load customers')));
    }
  }

  Future<void> changeUserRole(int? userId, String? newRole) async {
    if (userId == null || newRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select user and role'))
      );
      return;
    }

    try {
      await UserApiService.changeUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role updated successfully'))
      );

      await fetchUsers();

      setState(() {
        selectedUserForRoleChange = null;
        selectedNewRole = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change role'))
      );
    }
  }

  Future<void> assignSalesmanToTeamLeader(int? salesmanId, int? teamLeaderId) async {
    if (salesmanId == null || teamLeaderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select salesman and team leader'))
      );
      return;
    }

    try {
      await UserApiService.assignSalesmanToTeamLeader(salesmanId, teamLeaderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salesman assigned successfully'))
      );

      await fetchSalesmen();
      await fetchTeamLeaders();

      setState(() {
        selectedSalesman = null;
        selectedTeamLeader = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign salesman'))
      );
    }
  }

  Future<void> assignCustomersByCriteria(int? salesmanId) async {
    if (salesmanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select salesman'))
      );
      return;
    }

    try {
      await UserApiService.assignCustomersByCriteria(
        salesmanId,
        pipelineStage: selectedPipelineStage,
        leadStatus: selectedLeadStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customers assigned successfully'))
      );

      await fetchCustomers();

      setState(() {
        selectedSalesmanForCustomer = null;
        selectedPipelineStage = null;
        selectedLeadStatus = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign customers'))
      );
    }
  }

  Future<void> deleteUser(int userId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm) {
      await UserApiService.deleteUser(userId);
      fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text("User Management", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _navButton('User List'),
                  _navButton('Add New User'),
                  _navButton('Role Management'),
                  _navButton('Account Status'),
                  _navButton('Audit Logs'),
                  _navButton('Password Reset Requests'),
                  const Spacer(),
                  _backToDashboardButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: IndexedStack(
                index: _getUserPageIndex(selectedUserPage),
                children: [
                  _buildUserListPage(),
                  _buildAddUserPage(),
                  _buildRoleManagementPage(),
                  _buildAccountStatusPage(),
                  _buildAuditLogsPage(),
                  Center(child: Text("Password Reset Requests Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Status', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => accountTab = 'customer'),
                child: const Text('Customer Account Status'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => setState(() => accountTab = 'employee'),
                child: const Text('Employee Account Status'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: accountTab == 'customer'
                ? _buildCustomerAccountStatus()
                : _buildEmployeeAccountStatus(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeAccountStatus() {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return FutureBuilder<Map<String, int>>(
      future: UserApiService.getEmployeeStatusSummary(companyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }
        employeeStatusSummary = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            children: [
              const Text('Employee Status Summary', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: employeeStatusSummary.entries.map((e) {
                  return Chip(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    label: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildEmployeeListByStatus(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeeListByStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedEmployeeStatus,
          hint: const Text('Select Employee Status', style: TextStyle(color: Colors.white)),
          dropdownColor: Colors.blueGrey,
          items: ['Active', 'Inactive', 'Suspended', 'Terminated']
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (status) async {
  setState(() {
    selectedEmployeeStatus = status;
    isEmployeeLoading = true;
  });


  final salesmen = await UserApiService.getEmployeesByRoleAndStatus(companyId!, 'salesman', status: status!);
  final teamLeaders = await UserApiService.getEmployeesByRoleAndStatus(companyId!, 'team_leader', status: status);

  setState(() {
    employeeList = [...salesmen, ...teamLeaders];  // Combine both lists
    isEmployeeLoading = false;
  });
},

        ),
        const SizedBox(height: 10),
        isEmployeeLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: employeeList.length,
                  itemBuilder: (context, index) {
                    final employee = employeeList[index];
                    return Card(
                      color: Colors.white.withOpacity(0.85),
                      child: ListTile(
                        title: Text('${employee['full_name']} (${employee['role']})'),
                        subtitle: Text('Status: ${employee['account_status']} | Points: ${employee['reward_points']}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(icon: const Icon(Icons.update, color: Colors.blue), onPressed: () => _showEmployeeStatusDialog(employee)),
                            IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () => _updateEmployeePoints(employee, increment: true)),
                            IconButton(icon: const Icon(Icons.remove, color: Colors.red), onPressed: () => _updateEmployeePoints(employee, increment: false)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  void _showEmployeeStatusDialog(dynamic employee) {
    selectedNewEmployeeStatus = null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status for ${employee['full_name']}'),
        content: DropdownButton<String>(
          value: selectedNewEmployeeStatus,
          hint: const Text('Select New Status'),
          items: ['Active', 'Inactive', 'Suspended', 'Terminated']
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (val) => setState(() => selectedNewEmployeeStatus = val),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedNewEmployeeStatus == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a status')));
                return;
              }
              await UserApiService.updateEmployeeStatus(employee['id'], selectedNewEmployeeStatus!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status Updated')));
              Navigator.pop(context);
              setState(() => employeeList.removeWhere((e) => e['id'] == employee['id']));
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  Future<void> _updateEmployeePoints(dynamic employee, {required bool increment}) async {
    int currentPoints = employee['reward_points'] ?? 0;
    int newPoints = increment ? currentPoints + 1 : (currentPoints - 1).clamp(0, 9999);
    await UserApiService.updateEmployeeRewardPoints(employee['id'], newPoints);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Points Updated to $newPoints')));
    setState(() {
      employee['reward_points'] = newPoints;
    });
  }

  Widget _buildCustomerAccountStatus() {
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return FutureBuilder<Map<String, int>>(
      future: UserApiService.getCustomerStatusSummary(companyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
        }
        final statusData = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            children: [
              const Text('Customer Status Summary', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: statusData.entries.map((e) {
                  return Chip(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    label: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildCustomerStatusList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerStatusList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedCustomerStatus,
          hint: const Text('Select Status', style: TextStyle(color: Colors.white)),
          dropdownColor: Colors.blueGrey,
          items: ['Active', 'Inactive', 'Suspended', 'Prospect', 'Lost', 'Closed']
              .map((status) => DropdownMenuItem(value: status, child: Text(status)))
              .toList(),
          onChanged: (status) async {
            setState(() {
              selectedCustomerStatus = status;
              isCustomerLoading = true;
            });
            filteredCustomers = await UserApiService.getCustomersByStatus(companyId!, status!);
            setState(() => isCustomerLoading = false);
          },
        ),
        const SizedBox(height: 10),
        isCustomerLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        title: Text('${customer['name']}'),
                        subtitle: Text('Status: ${customer['account_status']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _showStatusChangeDialog(customer),
                          child: const Text('Change Status'),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  void _showStatusChangeDialog(dynamic customer) {
    String? newStatus;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Status for ${customer['name']}'),
          content: DropdownButton<String>(
            value: newStatus,
            hint: const Text('Select New Status'),
            items: ['Active', 'Inactive', 'Suspended', 'Prospect', 'Lost', 'Closed']
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (value) => setState(() => newStatus = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (newStatus == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a status')));
                  return;
                }
                await UserApiService.updateCustomerStatus(customer['id'], newStatus!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status Updated')));
                Navigator.pop(context);
                setState(() => filteredCustomers.removeWhere((c) => c['id'] == customer['id']));
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddUserPage() {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 550 : double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New User',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the details to create a new user account',
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(_nameController, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_emailController, 'Email', Icons.email),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'Phone', Icons.phone),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
            const SizedBox(height: 16),
            _buildRoleDropdown(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  if (_nameController.text.isEmpty ||
                      _emailController.text.isEmpty ||
                      _phoneController.text.isEmpty ||
                      _passwordController.text.isEmpty ||
                      selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all fields and select a role'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  await createUser(
                    fullName: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    password: _passwordController.text,
                    role: selectedRole!,
                    companyId: companyId!,
                  );

                  _nameController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                  _passwordController.clear();

                  setState(() {
                    selectedRole = null;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User Created Successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
                  'CREATE USER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
  return TextField(
    controller: controller,
    obscureText: isPassword,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    ),
  );
}

Widget _buildRoleDropdown() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey),
      color: Colors.grey[50],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: selectedRole,
        hint: const Text('Select Role'),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
        style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
        items: ['admin', 'team_leader', 'salesman'].map((role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(
              role.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(color: Colors.blueGrey),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedRole = value!),
      ),
    ),
  );
}

  Widget _buildUserListPage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () async {
        await fetchUsers();
        _refreshController.refreshCompleted();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];
          return Card(
            color: Colors.white.withOpacity(0.8),
            child: ListTile(
              title: Text(
                '${user['full_name'] ?? ''} - (${user['role'] ?? ''})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user['email'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteUser(user['id']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleManagementPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _expandableCard(
            title: "Change User Role",
            expanded: expandRole,
            onTap: () => setState(() => expandRole = !expandRole),
            child: Column(
              children: [
                userList.isEmpty
                    ? const Text('Loading Users...', style: TextStyle(color: Colors.white))
                    : DropdownButtonFormField<dynamic>(
                        value: selectedUserForRoleChange,
                        hint: const Text('Select User'),
                        decoration: _dropdownDecoration(),
                        items: userList.map((user) {
                          return DropdownMenuItem(
                            value: user,
                            child: Text('${user['full_name']} (${user['role']})'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedUserForRoleChange = value),
                      ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedNewRole,
                  hint: const Text('Select New Role'),
                  decoration: _dropdownDecoration(),
                  items: ['admin', 'team_leader', 'salesman'].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedNewRole = value),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUserForRoleChange == null || selectedNewRole == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select user and role')));
                    } else {
                      changeUserRole(selectedUserForRoleChange['id'], selectedNewRole);
                    }
                  },
                  child: const Text('Change Role'),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          _expandableCard(
            title: "Assign Salesman to Team Leader",
            expanded: expandSalesman,
            onTap: () => setState(() => expandSalesman = !expandSalesman),
            child: Column(
              children: [
                salesmanList.isEmpty
                    ? const Text('Loading Salesmen...', style: TextStyle(color: Colors.white))
                    : DropdownButtonFormField<dynamic>(
                        value: selectedSalesman,
                        hint: const Text('Select Salesman'),
                        decoration: _dropdownDecoration(),
                        items: salesmanList.map((user) {
                          return DropdownMenuItem(value: user, child: Text(user['full_name']));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedSalesman = value),
                      ),
                const SizedBox(height: 10),
                teamLeaderList.isEmpty
                    ? const Text('Loading Team Leaders...', style: TextStyle(color: Colors.white))
                    : DropdownButtonFormField<dynamic>(
                        value: selectedTeamLeader,
                        hint: const Text('Select Team Leader'),
                        decoration: _dropdownDecoration(),
                        items: teamLeaderList.map((user) {
                          return DropdownMenuItem(value: user, child: Text(user['full_name']));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedTeamLeader = value),
                      ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSalesman == null || selectedTeamLeader == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select salesman and team leader')));
                    } else {
                      assignSalesmanToTeamLeader(selectedSalesman['id'], selectedTeamLeader['id']);
                    }
                  },
                  child: const Text('Assign Salesman'),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          _expandableCard(
            title: "Assign Customers to Salesman by Criteria",
            expanded: expandCustomerCriteria,
            onTap: () => setState(() => expandCustomerCriteria = !expandCustomerCriteria),
            child: Column(
              children: [
                salesmanListForCustomer.isEmpty
                    ? const Text('Loading Salesmen...', style: TextStyle(color: Colors.white))
                    : DropdownButtonFormField<dynamic>(
                        value: selectedSalesmanForCustomer,
                        hint: const Text('Select Salesman'),
                        decoration: _dropdownDecoration(),
                        items: salesmanListForCustomer.map((user) {
                          return DropdownMenuItem(value: user, child: Text(user['full_name']));
                        }).toList(),
                        onChanged: (value) => setState(() => selectedSalesmanForCustomer = value),
                      ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedPipelineStage,
                  hint: const Text('Select Pipeline Stage'),
                  decoration: _dropdownDecoration(),
                  items: pipelineStages.map((stage) {
                    return DropdownMenuItem(value: stage, child: Text(stage));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPipelineStage = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedLeadStatus,
                  hint: const Text('Select Lead Status'),
                  decoration: _dropdownDecoration(),
                  items: leadStatuses.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedLeadStatus = value),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSalesmanForCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a salesman')));
                    } else {
                      assignCustomersByCriteria(selectedSalesmanForCustomer['id']);
                    }
                  },
                  child: const Text('Assign Customers'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Role Assignment Hierarchy", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          hierarchyData.isEmpty
              ? const CircularProgressIndicator()
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: hierarchyData.map((leader) {
                        return ExpansionTile(
                          title: Text('${leader['name']} (Team Leader)', style: const TextStyle(color: Colors.white)),
                          children: (leader['salesmen'] as List).map((salesman) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: ExpansionTile(
                                title: Text('${salesman['name']} (Salesman)', style: const TextStyle(color: Colors.white)),
                                children: (salesman['customers'] as List).map((customer) {
                                  return ListTile(
                                    title: Text(customer, style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _expandableCard({required String title, required bool expanded, required VoidCallback onTap, required Widget child}) {
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
              onTap: onTap,
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: child,
              )
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(),
    );
  }

  int _getUserPageIndex(String route) {
    final pages = [
      'User List',
      'Add New User',
      'Role Management',
      'Account Status',
      'Audit Logs',
      'Password Reset Requests'
    ];
    return pages.indexOf(route);
  }

  Widget _backToDashboardButton(BuildContext context) {
    return ListTile(
      title: const Text(
        "Back to Dashboard",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}