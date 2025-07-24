import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:flutter_web/sales_crm/tasks/task_list_screen.dart';
import '../../sales_crm/api/user_api_service.dart';
import 'user_selection_screen.dart';

class TaskTypeSelectionScreen extends StatefulWidget {
  final int companyId;
  final Customer customer;
  const TaskTypeSelectionScreen({super.key, required this.companyId,required this.customer});
  

  @override
  State<TaskTypeSelectionScreen> createState() => _TaskTypeSelectionScreenState();
}

class _TaskTypeSelectionScreenState extends State<TaskTypeSelectionScreen> {
  List<TaskType> taskTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTaskTypes();
  }

  Future<void> loadTaskTypes() async {
    setState(() => isLoading = true);
    try {
      final fetched = await UserApiService.fetchTaskTypes();

if (!mounted) return;

if (fetched.isEmpty) {
  final success = await UserApiService.initializeTaskTypes();
  if (success) {
    final retry = await UserApiService.fetchTaskTypes();
    if (mounted) {
      setState(() {
        taskTypes = retry;
        isLoading = false;
      });
    }
    return;
  }
}

if (mounted) {
  setState(() {
    taskTypes = fetched;
    isLoading = false;
  });
}

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error loading task types: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void onTaskTypeSelected(TaskType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSelectionScreen(
          companyId: widget.companyId,
          taskType: type,
          customer: widget.customer,
        ),
      ),
    );
  }

  void goToAssignedTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskListScreen(companyId: widget.companyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Task Type")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : taskTypes.isEmpty
              ? const Center(child: Text("No task types found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: goToAssignedTasks,
                          icon: const Icon(Icons.list_alt),
                          label: const Text("View Assigned Tasks"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          itemCount: taskTypes.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            final type = taskTypes[index];
                            return ElevatedButton(
                              onPressed: () => onTaskTypeSelected(type),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              child: Text(type.name),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
