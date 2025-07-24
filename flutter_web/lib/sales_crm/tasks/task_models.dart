class TaskType {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  TaskType({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory TaskType.fromJson(Map<String, dynamic> json) {
    return TaskType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class TaskAssignmentCreate {
  final String taskTypeId;
  final int assignedBy;
  final int assignedTo;
  final int customerId; // ✅ NEW
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final String priority;

  TaskAssignmentCreate({
    required this.taskTypeId,
    required this.assignedBy,
    required this.assignedTo,
    required this.customerId, // ✅ NEW
    this.title,
    this.description,
    this.dueDate,
    this.priority = "medium",
  });

  Map<String, dynamic> toJson() => {
        "task_type_id": taskTypeId,
        "assigned_by": assignedBy,
        "assigned_to": assignedTo,
        "customer_id": customerId, // ✅ NEW
        "title": title,
        "description": description,
        "due_date": dueDate?.toIso8601String(),
        "priority": priority,
      };
}

class TaskAssignment {
  final String id;
  final String taskTypeId;
  final int assignedBy;
  final int assignedTo;
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? completedAt;

  // ✅ New fields from enriched API
  final String? customerName;
  final String? assignedToName;

  TaskAssignment({
    required this.id,
    required this.taskTypeId,
    required this.assignedBy,
    required this.assignedTo,
    this.title,
    this.description,
    this.dueDate,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.completedAt,
    this.customerName,
    this.assignedToName,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) {
    return TaskAssignment(
      id: json['id'],
      taskTypeId: json['task_type_id'],
      assignedBy: json['assigned_by'],
      assignedTo: json['assigned_to'],
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      status: json['status'],
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      customerName: json['customer_name'],
      assignedToName: json['assigned_to_name'],
    );
  }
}


class TaskLog {
  final String id;
  final String taskId;
  final String action;
  final int performedBy;
  final DateTime performedAt;

  TaskLog({
    required this.id,
    required this.taskId,
    required this.action,
    required this.performedBy,
    required this.performedAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      id: json['id'],
      taskId: json['task_id'],
      action: json['action'],
      performedBy: json['performed_by'],
      performedAt: DateTime.parse(json['performed_at']),
    );
  }
}

class User {
  final int id;
  final String fullName;
  final String email;
  final String role;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => "$firstName $lastName";

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
