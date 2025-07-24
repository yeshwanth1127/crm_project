import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import '../../sales_crm/api/user_api_service.dart';
import 'assign_task_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  final int companyId;
  final TaskType taskType;
  final Customer customer;

  const UserSelectionScreen({
    super.key,
    required this.companyId,
    required this.taskType,
    required this.customer,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final result = await UserApiService.fetchSalesAndTeamUsers(widget.companyId);
      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load users: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  void onUserTap(User user) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AssignTaskScreen(
        companyId: widget.companyId,
        taskType: widget.taskType,
        user: user,
        customer: widget.customer, // ✅ pass the required customer object
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select User for '${widget.taskType.name}'"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.fullName[0])),
                      title: Text(user.fullName),
                      subtitle: Text("Role: ${user.role}"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => onUserTap(user),
                    );
                  },
                ),
    );
  }
}
