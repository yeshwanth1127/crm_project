import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/user_api_service.dart';

class PendingTasksPage extends StatefulWidget {
  final int salesmanId;
  const PendingTasksPage({super.key, required this.salesmanId});

  @override
  State<PendingTasksPage> createState() => _PendingTasksPageState();
}

class _PendingTasksPageState extends State<PendingTasksPage> {
  late Future<List<dynamic>> _futureTasks;

  @override
  void initState() {
    super.initState();
    _futureTasks = UserApiService.fetchPendingTasks(widget.salesmanId);
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'No due date';
    final date = DateTime.parse(isoDate);
    return DateFormat('MMM d, y – h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Tasks',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureTasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No pending tasks.', style: TextStyle(color: Colors.white)));
                }

                final tasks = snapshot.data!;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.white),
                        title: Text(t['title'] ?? 'No title', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${t['description'] ?? 'No description'}\nDue: ${_formatDate(t['due_date'])}\nPriority: ${t['priority'] ?? 'medium'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
