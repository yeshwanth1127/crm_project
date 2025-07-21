import 'package:flutter/material.dart';

class SupportStaffDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const SupportStaffDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Staff Dashboard - \$email')),
    );
  }
}
