import 'dart:convert';
import 'dart:ui';
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
  bool _isHoveringHome = false;

  final String backendUrl = 'http://192.168.0.14:8000/api/login';

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? '';
        final crmType = data['crm_type'] ?? '';
        final role = data['role'] ?? '';
        final companyId = data['company_id'];
        final userEmail = data['email'] ?? '';
        final userId = data['user_id'];
        await prefs.setInt('user_id', userId);
        
        await prefs.setString('token', token);
        await prefs.setString('crm_type', crmType);
        await prefs.setString('role', role);
        await prefs.setInt('company_id', companyId);
        await prefs.setString('email', userEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );

        navigateToDashboard(crmType, role, userEmail, companyId, userId);
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['detail'] ?? 'Invalid login';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void navigateToDashboard(String crmType, String role, String email, int companyId, int userId) {
    Widget destination;

    if (crmType == 'sales_crm') {
      if (role == 'admin') {
        destination = SalesAdminDashboard(companyId: companyId);
      } else if (role == 'team_leader') {
        destination = SalesTeamLeaderDashboard(companyId: companyId, email: email);
      } else {
        destination = SalesmanDashboard(companyId: companyId, email: email, salesmanId: userId);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // App Bar with Home Button
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringHome = true),
                    onExit: (_) => setState(() => _isHoveringHome = false),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context, 
                          '/', 
                          (route) => false
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isHoveringHome 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 28,
                              color: _isHoveringHome 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.8),
                            ),
                            if (!isSmallScreen) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Home',
                                style: TextStyle(
                                  color: _isHoveringHome 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'CRM Portal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the row
                ],
              ),
            ),

            // Login Form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: isSmallScreen ? screenWidth * 0.85 : 450,
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sign in to continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  decoration: _inputDecoration('Email', Icons.email_rounded),
                                  onChanged: (val) => email = val,
                                  validator: (val) => val!.contains('@') ? null : 'Invalid email',
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: _inputDecoration('Password', Icons.lock_rounded),
                                  obscureText: true,
                                  onChanged: (val) => password = val,
                                  validator: (val) => val!.length >= 6 ? null : 'Password too short',
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.pinkAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/onboarding'),
                                      child: const Text(
                                        "Sign up",
                                        style: TextStyle(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}