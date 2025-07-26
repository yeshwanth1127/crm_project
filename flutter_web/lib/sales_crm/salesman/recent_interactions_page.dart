import 'package:flutter/material.dart';

class RecentInteractionsPage extends StatelessWidget {
  final int salesmanId;

  const RecentInteractionsPage({super.key, required this.salesmanId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Recent Interactions Page - Salesman ID: $salesmanId",
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
