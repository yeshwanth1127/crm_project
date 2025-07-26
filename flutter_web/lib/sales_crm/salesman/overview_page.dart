import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';
import 'dart:async';

class OverviewPage extends StatefulWidget {
  final int salesmanId;

  const OverviewPage({required this.salesmanId});

  @override
  _OverviewPageState createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic> overview = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    try {
      final data = await UserApiService.fetchSalesmanOverview(widget.salesmanId);
      setState(() {
        overview = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        overview = {};
        loading = false;
      });
      print("Error loading overview: $e");
    }
  }

  Widget _buildStatCard(String label, int value, IconData icon) {
    return Container(
      width: 180,
      height: 140,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildStatCard("Total Customers", overview['total_customers'] ?? 0, Icons.people),
                _buildStatCard("Upcoming Followups", overview['upcoming_followups'] ?? 0, Icons.calendar_today),
                _buildStatCard("Pending Tasks", overview['pending_tasks'] ?? 0, Icons.assignment_late),
                _buildStatCard("Recent Interactions", overview['recent_interactions'] ?? 0, Icons.chat_bubble_outline),
              ],
            ),
          );
  }
}
