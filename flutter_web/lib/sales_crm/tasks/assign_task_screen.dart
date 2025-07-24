import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/tasks/task_models.dart';
import 'package:intl/intl.dart';
import '../../sales_crm/api/user_api_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final int companyId;
  final TaskType taskType;
  final User user;
  final Customer customer;

  const AssignTaskScreen({
    super.key,
    required this.companyId,
    required this.taskType,
    required this.user,
    required this.customer,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _dueDate;
  String _priority = 'medium';
  bool isSubmitting = false;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final task = TaskAssignmentCreate(
  taskTypeId: widget.taskType.id,
  assignedBy: 0, // TEMP: replace with actual admin ID if needed
  assignedTo: widget.user.id,
  customerId: widget.customer.id, // ✅ ADD THIS LINE
  title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
  description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
  dueDate: _dueDate,
  priority: _priority,
);


    final success = await UserApiService.assignTask(task);

    setState(() => isSubmitting = false);

    if (success) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Task assigned successfully!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to assign task'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final taskType = widget.taskType;

    return Scaffold(
      appBar: AppBar(title: const Text("Assign Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text("Task Type: ${taskType.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Assigning to: ${user.fullName} (${user.role})", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title (optional)"),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description (optional)"),
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      title: Text(_dueDate == null
                          ? "Select Due Date"
                          : "Due Date: ${DateFormat.yMMMd().format(_dueDate!)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _priority,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (value) => setState(() => _priority = value!),
                      decoration: const InputDecoration(labelText: "Priority"),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Assign Task"),
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
