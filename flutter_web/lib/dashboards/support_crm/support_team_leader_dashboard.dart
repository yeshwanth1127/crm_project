import 'package:flutter/material.dart';

class SupportTeamLeaderDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const SupportTeamLeaderDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support Team Leader Dashboard - \$email')),
    );
  }
}