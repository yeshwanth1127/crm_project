import 'package:flutter/material.dart';

class SalesmanDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const SalesmanDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Employee Dashboard - \$email")),
      body: Center(child: Text("Employee Dashboard for \$email at Company ID \$companyId")),
    );
  }
}