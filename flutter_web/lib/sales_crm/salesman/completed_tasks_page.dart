import 'package:flutter/material.dart';

class CompletedTasksPage extends StatelessWidget {
  final int salesmanId;

  const CompletedTasksPage({super.key, required this.salesmanId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Completed Tasks Page - Salesman ID: $salesmanId",
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
