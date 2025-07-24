import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:intl/intl.dart';
import '../../sales_crm/api/user_api_service.dart';

class TaskLogScreen extends StatefulWidget {
  final int companyId;
  const TaskLogScreen({super.key, required this.companyId});

  @override
  State<TaskLogScreen> createState() => _TaskLogScreenState();
}

class _TaskLogScreenState extends State<TaskLogScreen> {
  List<TaskLog> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    setState(() => isLoading = true);
    try {
      final result = await UserApiService.fetchTaskLogs(companyId: widget.companyId);
      setState(() {
        logs = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load task logs: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget buildLogCard(TaskLog log) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.history, color: Colors.grey),
        title: Text("Task ID: ${log.taskId}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Action: ${log.action}"),
            Text("Performed by: User ${log.performedBy}"),
            Text("Time: ${DateFormat.yMMMd().add_jm().format(log.performedAt)}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadLogs,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const Center(child: Text("No logs available"))
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return buildLogCard(logs[index]);
                  },
                ),
    );
  }
}
