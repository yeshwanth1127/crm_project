import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/user_management/user_management.dart';
import 'package:flutter_web/services/api_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  const Text("Admin Panel", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ..._navButtons(context),
                  const Spacer(),
                  _logoutButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: IndexedStack(
                index: _getPageIndex(selectedPage),
                children: [
                  _buildDashboardOverview(),
                  Center(child: Text("Customers Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Interactions Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Tasks Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Follow-ups Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Pipeline Analytics Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("User Management Page")),
                  Center(child: Text("Feature Settings Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                  Center(child: Text("Company Settings Page", style: TextStyle(color: Colors.white, fontSize: 20))),
                ],
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
    {'title': 'Dashboard Overview', 'route': '/dashboard-overview'},
    {'title': 'Customers', 'route': '/customers'},
    {'title': 'Interactions', 'route': '/interactions'},
    {'title': 'Tasks', 'route': '/tasks'},
    {'title': 'Follow-ups', 'route': '/followups'},
    {'title': 'Pipeline Analytics', 'route': '/pipeline-analytics'},
    {'title': 'User Management', 'route': '/user-management'},
    {'title': 'Feature Settings', 'route': '/feature-settings'},
    {'title': 'Company Settings', 'route': '/company-settings'},
  ];

  return pages.map((item) => ListTile(
    title: Text(item['title']!, style: const TextStyle(color: Colors.white)),
    onTap: () {
      if (item['title'] == 'User Management') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  UserManagementScreen()),
        );
      } else {
        setState(() {
          selectedPage = item['route']!;
        });
      }
    },
  )).toList();
}

  Widget _logoutButton(BuildContext context) {
    return ListTile(
      title: const Text(
        "Logout",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      },
    );
  }

  Widget _buildDashboardOverview() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Error loading dashboard", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: fetchDashboardData, child: const Text("Retry")),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome, Admin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    _buildDateFilters(),
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
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
            side: BorderSide(color: isSelected ? Colors.blue : Colors.grey),
            backgroundColor: isSelected ? Colors.blue.shade100 : Colors.white,
            foregroundColor: isSelected ? Colors.blue : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            setState(() {
              dateRange = filter;
              fetchDashboardData();
            });
          },
          child: Text(filter.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    final statsList = [
      {"title": "Customers", "value": stats["total_customers"] ?? 0},
      {"title": "Leads", "value": stats["leads"] ?? 0},
      {"title": "Clients", "value": stats["clients"] ?? 0},
      {"title": "Interactions", "value": stats["interactions"] ?? 0},
      {"title": "Tasks", "value": stats["pending_tasks"] ?? 0},
      {"title": "Followups", "value": stats["upcoming_followups"] ?? 0},
    ];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: statsList.length,
          itemBuilder: (context, index) {
            final item = statsList[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${item["value"]}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(item["title"]!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Basic Analytics Graph", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: const FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(stats.length, (i) => FlSpot(i.toDouble(), (stats.values.elementAt(i) as num).toDouble())),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}