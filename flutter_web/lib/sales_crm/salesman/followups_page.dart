import 'package:flutter/material.dart';

class FollowUpsPage extends StatelessWidget {
  final int salesmanId;

  const FollowUpsPage({super.key, required this.salesmanId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "My Follow Ups Page - Salesman ID: $salesmanId",
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
