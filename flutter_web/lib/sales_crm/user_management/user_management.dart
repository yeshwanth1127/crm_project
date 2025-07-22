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
  String? selectedRole;
  String selectedUserPage = 'User List';
  int? companyId;
  List<dynamic> userList = [];
  bool isLoading = true;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

@override
void initState() {
  super.initState();
  loadCompanyIdAndFetchUsers();
}

Future<void> loadCompanyIdAndFetchUsers() async {
  final prefs = await SharedPreferences.getInstance();
  companyId = prefs.getInt('company_id');
  if (companyId != null) {
    fetchUsers();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Company ID not found')));
  }
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
                  Center(child: Text("Role Management Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Account Status Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Audit Logs Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Password Reset Requests Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildAddUserPage() {


  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add New User', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name', fillColor: Colors.white, filled: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email', fillColor: Colors.white, filled: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone', fillColor: Colors.white, filled: true),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password', fillColor: Colors.white, filled: true),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        DropdownButton<String>(
  value: selectedRole,
  hint: const Text('Select Role', style: TextStyle(color: Colors.white)),
  items: ['admin', 'team_leader', 'salesman'].map((role) {
    return DropdownMenuItem<String>(
      value: role,
      child: Text(role, style: const TextStyle(color: Colors.black)),
    );
  }).toList(),
  onChanged: (value) => setState(() => selectedRole = value!),
),
        const SizedBox(height: 20),
        ElevatedButton(
  onPressed: () async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields and select a role')));
      return;
    }

    await createUser(
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      role: selectedRole!,  // safe after validation
      companyId: companyId!,
    );

    // Clear form inputs after successful creation
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();

    setState(() {
      selectedRole = null;  // reset role selection properly
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Created Successfully')));
  },
  child: const Text('Create User'),
),


      ],
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
