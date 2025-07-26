import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web/dashboards/sales_crm/salesman_dashboard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// CRM Dashboards
import '../dashboards/sales_crm/admin_dashboard.dart';
import '../dashboards/sales_crm/team_leader_dashboard.dart';
import '../dashboards/marketing_crm/admin_dashboard.dart' as marketing_admin;
import '../dashboards/marketing_crm/team_leader_dashboard.dart' as marketing_team_leader;
import '../dashboards/marketing_crm/marketing_staff_dashboard.dart' as marketing_staff;
import '../dashboards/support_crm/admin_dashboard.dart' as support_admin;
import '../dashboards/support_crm/support_team_leader_dashboard.dart' as support_team_leader;
import '../dashboards/support_crm/support_staff_dashboard.dart' as support_staff;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String fullName = '', email = '', phone = '', password = '', confirmPassword = '';
  bool isLoading = false;
  final String backendUrl = 'http://127.0.0.1:8000/api/register';

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company_id');

    if (companyId == null || companyId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company ID missing. Restart onboarding.')),
      );
      setState(() => isLoading = false);
      return;
    }

    final body = jsonEncode({
      "company_id": companyId,
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "password": password,
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        prefs.setString('crm_type', data['crm_type']);
        prefs.setString('role', data['role']);
        prefs.setString('email', data['email']);
        prefs.setInt('company_id', data['company_id']);
        prefs.setInt('user_id', data['user_id']);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        // ✅ Pass user_id as salesmanId
        navigateToDashboard(
          data['crm_type'],
          data['role'],
          data['email'],
          data['company_id'],
          data['user_id'],
        );
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void navigateToDashboard(String crmType, String role, String email, int companyId, int userId) {
    Widget destination;

    if (crmType == 'sales_crm') {
      destination = role == 'admin'
          ? SalesAdminDashboard(companyId: companyId)
          : role == 'team_leader'
              ? SalesTeamLeaderDashboard(companyId: companyId, email: email)
              : SalesmanDashboard(companyId: companyId, email: email, salesmanId: userId);
    } else if (crmType == 'marketing_crm') {
      destination = role == 'admin'
          ? marketing_admin.AdminDashboard(companyId: companyId)
          : role == 'team_leader'
              ? marketing_team_leader.TeamLeaderDashboard(companyId: companyId, email: email)
              : marketing_staff.MarketingStaffDashboard(companyId: companyId, email: email);
    } else if (crmType == 'support_crm') {
      destination = role == 'admin'
          ? support_admin.AdminDashboard(companyId: companyId)
          : role == 'team_leader'
              ? support_team_leader.SupportTeamLeaderDashboard(companyId: companyId, email: email)
              : support_staff.SupportStaffDashboard(companyId: companyId, email: email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid CRM Type')),
      );
      return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Admin Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Owner Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _textInput('Full Name', (val) => fullName = val),
              _textInput('Email', (val) => email = val, validator: (val) =>
                  val!.contains('@') ? null : 'Invalid email'),
              _textInput('Phone Number', (val) => phone = val, validator: (val) =>
                  val!.length < 8 ? 'Invalid phone number' : null),
              _textInput('Password', (val) => password = val, obscure: true, validator: (val) =>
                  val!.length < 6 ? 'Minimum 6 characters' : null),
              _textInput('Confirm Password', (val) => confirmPassword = val, obscure: true, validator: (val) =>
                  val != password ? 'Passwords do not match' : null),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textInput(String label, Function(String) onChanged,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        obscureText: obscure,
        onChanged: onChanged,
        validator: validator ?? (val) => val!.isEmpty ? 'Required' : null,
      ),
    );
  }
}
