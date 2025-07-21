import 'package:flutter/material.dart';

class SalesTeamLeaderDashboard extends StatelessWidget {
  final int companyId;
  final String email;
  const SalesTeamLeaderDashboard({super.key, required this.companyId, required this.email});

  @override
  Widget build(BuildContext context) { 
    return Scaffold(appBar: AppBar(title: const Text('Sales Team Leader Dashboard')));
   }
}




    
