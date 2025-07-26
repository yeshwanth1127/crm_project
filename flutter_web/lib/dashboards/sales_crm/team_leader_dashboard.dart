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
    final token = prefs.getString('token') ?? '';
    final companyId = widget.companyId;
    final email = widget.email;

    final userId = await UserApiService.getTeamLeaderIdByEmail(email, token, companyId);
    final overview = await UserApiService.getTeamLeaderOverview(userId, token);
    teamLeaderName = email.split('@').first; // Fallback if name is not available
    return overview;
  }

  @override
  void initState() {
    super.initState();
    dashboardData = fetchDashboardData();
  }

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'Overview', 'icon': Icons.dashboard_rounded},
    {'title': 'Salesman List', 'icon': Icons.group_rounded},
    {'title': 'Customers List', 'icon': Icons.people_alt_rounded},
    {'title': 'Assign Task', 'icon': Icons.assignment_ind_rounded},
    {'title': 'Task Logs', 'icon': Icons.list_alt_rounded},
    {'title': 'Interactions', 'icon': Icons.chat_bubble_rounded},
    {'title': 'Reward & Status', 'icon': Icons.star_rounded},
    {'title': 'Logout', 'icon': Icons.logout_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Team Leader',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white54, thickness: 1, height: 1),
                  const SizedBox(height: 16),

                  // Navigation Menu
                  Expanded(
                    child: ListView.builder(
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        final title = item['title'] as String;
                        final icon = item['icon'] as IconData;
                        final isSelected = index == selectedIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () async {
                                if (title == 'Logout') {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                } else {
                                  setState(() => selectedIndex = index);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected ? Colors.white : Colors.white70,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF00B4DB).withOpacity(0.97),
                          const Color(0xFF0083B0).withOpacity(0.97),
                        ],
                      ),
                    ),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: dashboardData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        } else {
                          final data = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: IndexedStack(
                              index: selectedIndex,
                              children: [
                                _buildOverview(data),
                                SalesmanListPage(salesmen: List<Map<String, dynamic>>.from(data['salesmen'] ?? [])),
                                CustomerListPage(customers: List<Map<String, dynamic>>.from(data['customers'] ?? [])),
                                _buildComingSoon('Assign Task'),
                                _buildComingSoon('Task Logs'),
                                _buildComingSoon('Interactions'),
                                _buildComingSoon('Reward & Status Management'),
                                Container(), // Placeholder for logout
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(Map<String, dynamic> data) {
    final taskSummary = Map<String, dynamic>.from(data['task_summary'] ?? {});
    final followups = Map<String, dynamic>.from(data['followups'] ?? {});

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Leader Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildStatCard(
                'Sales Team',
                (data['salesmen'] as List?)?.length.toString() ?? '0',
                Icons.group_rounded,
                Colors.blueAccent,
              ),
              _buildStatCard(
                'Customers',
                (data['customers'] as List?)?.length.toString() ?? '0',
                Icons.people_alt_rounded,
                Colors.tealAccent,
              ),
              _buildStatCard(
                'Pending Tasks',
                taskSummary['assigned']?.toString() ?? '0',
                Icons.assignment_late_rounded,
                Colors.orangeAccent,
              ),
              _buildStatCard(
                'Today\'s Followups',
                followups['due_today']?.toString() ?? '0',
                Icons.calendar_today_rounded,
                Colors.purpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            '$title\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}