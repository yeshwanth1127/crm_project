import 'package:flutter/material.dart';
import 'package:flutter_web/dashboards/marketing_crm/admin_dashboard.dart' as marketing_admin;
import 'package:flutter_web/dashboards/marketing_crm/marketing_staff_dashboard.dart';
import 'package:flutter_web/dashboards/sales_crm/admin_dashboard.dart';
import 'package:flutter_web/dashboards/sales_crm/salesman_dashboard.dart';
import 'package:flutter_web/dashboards/sales_crm/team_leader_dashboard.dart';
import 'package:flutter_web/dashboards/support_crm/admin_dashboard.dart' as support_admin;
import 'package:flutter_web/dashboards/support_crm/support_staff_dashboard.dart';
import 'package:flutter_web/sales_crm/interactions/interaction_form_screen.dart';
import 'package:flutter_web/sales_crm/interactions/interaction_timeline_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/landing_screen.dart';
import 'pages/onboarding_screen.dart';
import 'pages/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyCRMApp());
}

class MyCRMApp extends StatelessWidget {
  const MyCRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Platform',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashDecider(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/log-interaction': (context) => LogInteractionFormScreen(),
        '/interaction-timeline': (context) => InteractionTimelineScreen(),
      },
    );
  }
}

class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? role = prefs.getString('role');
    final String? crmType = prefs.getString('crm_type');
    final String? email = prefs.getString('email');
    final int? companyId = prefs.getInt('company_id');
    final int? userId = prefs.getInt('user_id'); // used for salesmanId

    if (role != null && crmType != null && email != null && companyId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => determineDashboard(crmType, role, email, companyId, userId),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
      );
    }
  }

  Widget determineDashboard(String crmType, String role, String email, int companyId, int? userId) {
    if (crmType == 'sales_crm') {
      if (role == 'admin') {
        return SalesAdminDashboard(companyId: companyId);
      } else if (role == 'team_leader') {
        return SalesTeamLeaderDashboard(companyId: companyId, email: email);
      } else if (role == 'employee') {
        return SalesmanDashboard(
          companyId: companyId,
          email: email,
          salesmanId: userId ?? 0, // fallback to 0 if null
        );
      }
    } else if (crmType == 'marketing_crm') {
      if (role == 'admin') {
        return marketing_admin.AdminDashboard(companyId: companyId);
      } else if (role == 'employee') {
        return MarketingStaffDashboard(companyId: companyId, email: email);
      }
    } else if (crmType == 'support_crm') {
      if (role == 'admin') {
        return support_admin.AdminDashboard(companyId: companyId);
      } else if (role == 'employee') {
        return SupportStaffDashboard(companyId: companyId, email: email);
      }
    }

    return const LandingScreen(); // fallback
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
