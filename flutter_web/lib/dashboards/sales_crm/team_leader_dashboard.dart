import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';
import 'package:flutter_web/sales_crm/team_leader/customer_list_page.dart';
import 'package:flutter_web/sales_crm/team_leader/salesman_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SalesTeamLeaderDashboard extends StatefulWidget {
  final int companyId;
  final String email;

  const SalesTeamLeaderDashboard({
    super.key,
    required this.companyId,
    required this.email,
  });

  @override
  State<SalesTeamLeaderDashboard> createState() => _SalesTeamLeaderDashboardState();
}

class _SalesTeamLeaderDashboardState extends State<SalesTeamLeaderDashboard> {
  int selectedIndex = 0;
  late Future<Map<String, dynamic>> dashboardData;
  String teamLeaderName = '';

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')!;
    final companyId = widget.companyId;
    final email = widget.email;

    final userId = await UserApiService.getTeamLeaderIdByEmail(email, token, companyId);
    final overview = await UserApiService.getTeamLeaderOverview(userId, token);
    teamLeaderName = email.split('@')[0]; // Fallback if name is not available
    return overview;
  }

  @override
  void initState() {
    super.initState();
    dashboardData = fetchDashboardData();
  }

  final List<String> sections = [
    'Overview',
    'Salesman List',
    'Customers List',
    'Assign Task',
    'Task Logs',
    'Interactions',
    'Reward & Status',
    'Logout'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA), Color(0xFF4DD0E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Welcome,\n${widget.email.split('@')[0]}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(color: Colors.white54, thickness: 1, height: 30),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: Icon(
                                index == 0
                                    ? Icons.dashboard
                                    : index == 1
                                        ? Icons.group
                                        : index == 2
                                            ? Icons.person
                                            : index == 3
                                                ? Icons.assignment
                                                : index == 4
                                                    ? Icons.list_alt
                                                    : index == 5
                                                        ? Icons.chat
                                                        : index == 6
                                                            ? Icons.star
                                                            : Icons.logout,
                              ),
                              title: Text(
                                sections[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                              selected: index == selectedIndex,
                              selectedTileColor: Colors.white.withOpacity(0.3),
                              onTap: () async {
                                if (sections[index] == 'Logout') {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                } else {
                                  setState(() => selectedIndex = index);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: dashboardData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final data = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IndexedStack(
                        index: selectedIndex,
                        children: [
                          _buildOverview(data),
                          SalesmanListPage(salesmen: data['salesmen']),
                          CustomerListPage(customers: data['customers']),

                          Center(child: Text('Assign Task (Coming Soon)')),
                          Center(child: Text('Task Logs (Coming Soon)')),
                          Center(child: Text('Interactions (Coming Soon)')),
                          Center(child: Text('Reward & Status Management (Coming Soon)')),
                          Container(), // Placeholder for logout
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard('Salesmen', data['salesmen'].length.toString(), Icons.group),
            _buildStatCard('Customers', data['customers'].length.toString(), Icons.person),
            _buildStatCard('Pending Tasks', data['task_summary']['assigned'].toString(), Icons.assignment_late),
            _buildStatCard('Followups Today', data['followups']['due_today'].toString(), Icons.calendar_today),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: Colors.teal),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }


}
