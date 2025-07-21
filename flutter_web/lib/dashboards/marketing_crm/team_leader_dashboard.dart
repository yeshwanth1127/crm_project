import 'package:flutter/material.dart';

class TeamLeaderDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const TeamLeaderDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marketing Team Leader Dashboard - \$email')),
    );
  }
}