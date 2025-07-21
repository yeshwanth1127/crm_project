import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Sales CRM dashboards
import '../dashboards/sales_crm/admin_dashboard.dart';
import '../dashboards/sales_crm/team_leader_dashboard.dart';
import '../dashboards/sales_crm/salesman_dashboard.dart';

// ✅ Marketing CRM dashboards
import '../dashboards/marketing_crm/admin_dashboard.dart' as marketing_admin;
import '../dashboards/marketing_crm/team_leader_dashboard.dart' as marketing_team_leader;
import '../dashboards/marketing_crm/marketing_staff_dashboard.dart' as marketing_staff;

// ✅ Support CRM dashboards
import '../dashboards/support_crm/admin_dashboard.dart' as support_admin;
import '../dashboards/support_crm/support_team_leader_dashboard.dart' as support_team_leader;
import '../dashboards/support_crm/support_staff_dashboard.dart' as support_staff;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  bool isLoading = false;

  final String backendUrl = 'http://192.168.0.137:8000/api/login';

  Future<void> login() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    final response = await http.post(
  Uri.parse(backendUrl),
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: {
    "email": email,
    "password": password,
  },
);
;


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final crmType = data['crm_type'];
      final role = data['role'];
      final companyId = data['company_id'];
      final userEmail = data['email'];

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('crm_type', crmType);
      prefs.setString('role', role);
      prefs.setInt('company_id', companyId);
      prefs.setString('email', userEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful!')),
      );

      navigateToDashboard(crmType, role, userEmail, companyId);
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['detail'] ?? 'Invalid login')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


 void navigateToDashboard(String crmType, String role, String email, int companyId) {
  Widget destination;

  if (crmType == 'sales_crm') {
    if (role == 'admin') {
      destination = SalesAdminDashboard(companyId: companyId);
    } else if (role == 'team_leader') {
      destination = SalesTeamLeaderDashboard(companyId: companyId, email: email);
    } else {
      destination = SalesmanDashboard(companyId: companyId, email: email);
    }
  } else if (crmType == 'marketing_crm') {
    if (role == 'admin') {
      destination = marketing_admin.AdminDashboard(companyId: companyId);
    } else if (role == 'team_leader') {
      destination = marketing_team_leader.TeamLeaderDashboard(companyId: companyId, email: email);
    } else {
      destination = marketing_staff.MarketingStaffDashboard(companyId: companyId, email: email);
    }
  } else if (crmType == 'support_crm') {
    if (role == 'admin') {
      destination = support_admin.AdminDashboard(companyId: companyId);
    } else if (role == 'team_leader') {
      destination = support_team_leader.SupportTeamLeaderDashboard(companyId: companyId, email: email);
    } else {
      destination = support_staff.SupportStaffDashboard(companyId: companyId, email: email);
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid CRM type')));
    return;
  }

  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loginn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (val) => email = val,
                validator: (val) => val!.contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => password = val,
                validator: (val) => val!.length >= 6 ? null : 'Password too short',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
