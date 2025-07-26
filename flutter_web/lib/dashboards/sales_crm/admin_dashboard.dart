import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';
import 'package:flutter_web/sales_crm/interactions/interactions_home_screen.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:flutter_web/sales_crm/tasks/task_type_selection_screen.dart';
import 'package:flutter_web/sales_crm/user_management/user_management.dart';
import 'package:flutter_web/services/api_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_web/sales_crm/customers/customers_home.dart';

class SalesAdminDashboard extends StatefulWidget {
  final int companyId;
  const SalesAdminDashboard({super.key, required this.companyId});

  @override
  State<SalesAdminDashboard> createState() => _SalesAdminDashboardState();
}

class _SalesAdminDashboardState extends State<SalesAdminDashboard> {
  String selectedPage = '/dashboard-overview';
  Map<String, dynamic> stats = {};
  List<String> features = [];
  bool isLoading = true;
  bool isError = false;
  String dateRange = 'all';
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<Customer> fetchCustomer() async {
    final customers = await UserApiService.fetchCustomers(widget.companyId);
    if (customers.isNotEmpty) {
      return customers.first;
    } else {
      throw Exception("No customers available");
    }
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      isError = false;
    });
    try {
      stats = await ApiService.fetchDashboardStats(widget.companyId, dateRange);
      features = await ApiService.fetchSelectedFeatures(widget.companyId);
      isLoading = false;
    } catch (e) {
      isLoading = false;
      isError = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF2193b0).withOpacity(0.9),
              Color(0xFF6dd5ed).withOpacity(0.9),
            ],
            stops: [0.1, 1.0],
          ),
        ),
        child: Row(
          children: [
            // Left Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: Offset(5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  // Admin Profile Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
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
                            gradient: LinearGradient(
                              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
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
                          child: Center(
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Admin Panel",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Company ID: ${widget.companyId}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Navigation Menu
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _navButtons(context),
                      ),
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (route) => false);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2193b0).withOpacity(0.97),
                          Color(0xFF6dd5ed).withOpacity(0.97),
                        ],
                      ),
                    ),
                    child: IndexedStack(
                      index: _getPageIndex(selectedPage),
                      children: [
                        _buildDashboardOverview(),
                        CustomersHome(companyId: widget.companyId),
                        InteractionsHomeScreen(),
                        FutureBuilder<Customer>(
                          future: fetchCustomer(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: CircularProgressIndicator(
                                color: Colors.white,
                              ));
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text("Error: ${snapshot.error}",
                                      style: TextStyle(color: Colors.white)));
                            } else if (snapshot.hasData) {
                              return TaskTypeSelectionScreen(
                                companyId: widget.companyId,
                                customer: snapshot.data!,
                              );
                            } else {
                              return Center(
                                  child: Text("No customer found",
                                      style: TextStyle(color: Colors.white)));
                            }
                          },
                        ),
                        Center(
                            child: Text("Follow-ups Page",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))),
                        Center(
                            child: Text("Pipeline Analytics Page",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))),
                        Center(child: Text("User Management Page")),
                        Center(
                            child: Text("Feature Settings Page",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))),
                        Center(
                            child: Text("Company Settings Page",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20))),
                      ],
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

  int _getPageIndex(String route) {
    final pages = [
      '/dashboard-overview',
      '/customers',
      '/interactions',
      '/tasks',
      '/followups',
      '/pipeline-analytics',
      '/user-management',
      '/feature-settings',
      '/company-settings',
    ];
    return pages.indexOf(route);
  }

  List<Widget> _navButtons(BuildContext context) {
    final pages = [
      {
        'title': 'Dashboard Overview',
        'route': '/dashboard-overview',
        'icon': Icons.dashboard_rounded
      },
      {
        'title': 'User Management',
        'route': '/user-management',
        'icon': Icons.people_alt_rounded
      },
      {'title': 'Customers', 'route': '/customers', 'icon': Icons.group_rounded},
      {
        'title': 'Interactions',
        'route': '/interactions',
        'icon': Icons.chat_bubble_rounded
      },
      {'title': 'Tasks', 'route': '/tasks', 'icon': Icons.task_rounded},
      {
        'title': 'Follow-ups',
        'route': '/followups',
        'icon': Icons.notifications_active_rounded
      },
      {
        'title': 'Pipeline Analytics',
        'route': '/pipeline-analytics',
        'icon': Icons.analytics_rounded
      },
      {
        'title': 'Feature Settings',
        'route': '/feature-settings',
        'icon': Icons.settings_applications_rounded
      },
      {
        'title': 'Company Settings',
        'route': '/company-settings',
        'icon': Icons.business_rounded
      },
    ];

    return pages.map((item) {
  final route = item['route'] as String? ?? '';
  final title = item['title'] as String? ?? '';
  final icon = item['icon'] as IconData? ?? Icons.error;
  
  final isSelected = selectedPage == route;
  
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (title == 'User Management') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserManagementScreen()),
            );
          } else {
            setState(() {
              selectedPage = route;
            });
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
}).toList();
  }

  Widget _buildDashboardOverview() {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
        : isError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error loading dashboard",
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: fetchDashboardData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF2193b0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text("Retry"),
                    ),
                  ],
                ),
              )
            : SmartRefresher(
                controller: _refreshController,
                onRefresh: () async {
                  await fetchDashboardData();
                  _refreshController.refreshCompleted();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, Admin",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDateFilters(),
                      SizedBox(height: 24),
                      _buildStatsCards(),
                      SizedBox(height: 24),
                      _buildAnalyticsGraph(),
                    ],
                  ),
                ),
              );
  }

  Widget _buildDateFilters() {
    final filters = ["today", "week", "month", "all"];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: filters.map((filter) {
        final isSelected = filter == dateRange;
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5)),
            backgroundColor:
                isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            setState(() {
              dateRange = filter;
              fetchDashboardData();
            });
          },
          child: Text(
            filter.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
  final statsList = [
    {"title": "Customers", "value": (stats["total_customers"] ?? 0).toString()},
    {"title": "Leads", "value": (stats["leads"] ?? 0).toString()},
    {"title": "Clients", "value": (stats["clients"] ?? 0).toString()},
    {"title": "Interactions", "value": (stats["interactions"] ?? 0).toString()},
    {"title": "Tasks", "value": (stats["pending_tasks"] ?? 0).toString()},
    {"title": "Followups", "value": (stats["upcoming_followups"] ?? 0).toString()},
  ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: statsList.length,
          itemBuilder: (context, index) {
            final item = statsList[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${item["value"]}",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item["title"]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsGraph() {
  // Convert stats values to double explicitly
  final spots = stats.entries.map((entry) {
    final value = entry.value is num ? (entry.value as num).toDouble() : 0.0;
    return FlSpot(entry.key.length.toDouble(), value);
  }).toList();

  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Analytics Overview",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.white,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  dotData: FlDotData(show: false),
                ),
              ],
              minX: 0,
              maxX: spots.isNotEmpty ? spots.last.x : 0,
              minY: 0,
              maxY: spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1 : 0,
            ),
          ),
        ),
      ],
    ),
  );
}

}