import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final int companyId;
  const AdminDashboard({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Admin Dashboard - Company \$companyId')),
    );
  }
}