import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:intl/intl.dart';
import '../../sales_crm/api/user_api_service.dart';

class TaskListScreen extends StatefulWidget {
  final int companyId;
  const TaskListScreen({super.key, required this.companyId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<TaskAssignment> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => isLoading = true);
    try {
      final result = await UserApiService.fetchTasksByCompany(
  widget.companyId,
);

      setState(() {
        tasks = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to load tasks: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> completeTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Mark Task Completed"),
        content: const Text("Are you sure you want to mark this task as completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await UserApiService.markTaskAsCompleted(taskId);
    if (success) {
      setState(() {
        tasks.removeWhere((t) => t.id == taskId);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Task marked as completed"),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to mark task completed"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget buildTaskCard(TaskAssignment task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.assignment_turned_in, color: Colors.orange),
        title: Text(task.title ?? task.taskTypeId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assigned to: ${task.assignedTo}"),
            Text("Priority: ${task.priority.toUpperCase()}"),
            if (task.dueDate != null)
              Text("Due: ${DateFormat.yMMMd().format(task.dueDate!)}"),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: () => completeTask(task.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadTasks,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? const Center(child: Text("No assigned tasks found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return buildTaskCard(tasks[index]);
                    },
                  ),
                ),
    );
  }
}
