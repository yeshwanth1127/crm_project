import 'package:flutter/material.dart';

class MyPointsPage extends StatelessWidget {
  final int salesmanId;

  const MyPointsPage({super.key, required this.salesmanId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "My Points Page - Salesman ID: $salesmanId",
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
