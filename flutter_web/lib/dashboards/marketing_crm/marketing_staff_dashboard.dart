import 'package:flutter/material.dart';

class MarketingStaffDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const MarketingStaffDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marketing Staff Dashboard - \$email')),
    );
  }
}