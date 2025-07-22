import 'package:flutter/material.dart';
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
  bool isLoading = true;
  bool isError = false;
  Map<String, dynamic> stats = {};
  List<String> features = [];
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

  void _onRefresh() async {
    await fetchDashboardData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Error loading dashboard"),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: fetchDashboardData, child: const Text("Retry")),
                    ],
                  ),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome, Admin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildDateFilters(),
                        const SizedBox(height: 16),
                        _buildStatsCards(),
                        const SizedBox(height: 24),
                        _buildFeatureCards(),
                        const SizedBox(height: 24),
                        _buildAnalyticsGraph(),
                        const SizedBox(height: 24),
                        _buildUserManagementSection(),
                        const SizedBox(height: 24),
                        _buildSettingsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["today", "week", "month", "all"].map((filter) {
        final isSelected = filter == dateRange;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey,
          ),
          onPressed: () {
            dateRange = filter;
            fetchDashboardData();
          },
          child: Text(filter.toUpperCase()),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    final statsList = stats.entries.map((entry) => {"title": entry.key, "count": entry.value}).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.3, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: statsList.length,
      itemBuilder: (context, index) {
        final item = statsList[index];
        return Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item['title'].toString().toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${item['count']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureCards() {
    final allFeatures = [
      {"title": "Customers", "route": "/customers"},
      {"title": "Interactions", "route": "/interactions"},
      {"title": "Tasks", "route": "/tasks"},
      {"title": "Followups", "route": "/followups"},
    ];

    return ExpansionTile(
      title: const Text("Core Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: allFeatures.where((feature) => features.contains(feature["title"]?.toLowerCase())).map((feature) {
        return ListTile(
          title: Text(feature["title"]!),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => Navigator.pushNamed(context, feature["route"]!),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Basic Analytics Graph", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(show: false),
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
        )
      ],
    );
  }

  Widget _buildUserManagementSection() {
    return ExpansionTile(
      title: const Text("User Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, "/create-user"),
          child: const Text("Add New User"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, "/list-users"),
          child: const Text("View All Users"),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return ExpansionTile(
      title: const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, "/feature-settings"),
          child: const Text("Manage Features"),
        ),
        ElevatedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // clear session data

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false, // removes all previous routes
      );
    }
  },
  child: const Text("Logout"),
),

      ],
    );
  }
}
