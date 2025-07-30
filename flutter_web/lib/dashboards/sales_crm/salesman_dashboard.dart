

import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/salesman/completed_tasks_page.dart';
import 'package:flutter_web/sales_crm/salesman/customers_assigned_page.dart';
import 'package:flutter_web/sales_crm/salesman/followups_page.dart';
import 'package:flutter_web/sales_crm/salesman/my_points_page.dart';
import 'package:flutter_web/sales_crm/salesman/overview_page.dart';
import 'package:flutter_web/sales_crm/salesman/pending_tasks_page.dart';
import 'package:flutter_web/sales_crm/salesman/recent_interactions_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesmanDashboard extends StatefulWidget {
  final int salesmanId;
  final int companyId;
  final String email;

  const SalesmanDashboard({
    Key? key,
    required this.salesmanId,
    required this.companyId,
    required this.email,
  }) : super(key: key);

  @override
  _SalesmanDashboardState createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  int _selectedIndex = 0;
  bool _isHoveringLogout = false;

  late final List<Widget> _pages = [
    OverviewPage(salesmanId: widget.salesmanId),
    CustomersAssignedPage(salesmanId: widget.salesmanId),
    FollowUpsPage(salesmanId: widget.salesmanId),
    PendingTasksPage(salesmanId: widget.salesmanId),
    RecentInteractionsPage(salesmanId: widget.salesmanId),
    CompletedTasksPage(salesmanId: widget.salesmanId),
    MyPointsPage(salesmanId: widget.salesmanId),
  ];

  final List<String> _menuLabels = [
    "Overview",
    "Customers Assigned",
    "My Follow Ups",
    "Pending Tasks",
    "Recent Interactions",
    "Completed Tasks",
    "My Points",
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.track_changes_rounded,
    Icons.pending_actions_rounded,
    Icons.history_rounded,
    Icons.check_circle_rounded,
    Icons.star_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color.fromARGB(255, 148, 197, 230),
              Color.fromARGB(255, 31, 163, 230),
            ],
            stops: [0.1, 1.0],
          ),
        ),
        child: Row(
          children: [

            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Color(0xFF1C1C2D).withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 40),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {

                      },
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            "Sales Dashboard",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),


                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          _menuLabels.length,
                          (i) => Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: _NavItem(
                              icon: _menuIcons[i],
                              label: _menuLabels[i],
                              isSelected: _selectedIndex == i,
                              onTap: () => setState(() => _selectedIndex = i),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),


                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringLogout = true),
                      onExit: (_) => setState(() => _isHoveringLogout = false),
                      child: GestureDetector(
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isHoveringLogout
                                ? Colors.red.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isHoveringLogout
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: _isHoveringLogout
                                    ? Colors.redAccent
                                    : Colors.white70,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: _isHoveringLogout
                                      ? Colors.redAccent
                                      : Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),


            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF16222A).withOpacity(0.97),
                          Color(0xFF3A6073).withOpacity(0.97),
                        ],
                      ),
                    ),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
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
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Color(0xFF00C6FB).withOpacity(0.2),
                      Color(0xFF005BEA).withOpacity(0.2),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            border: isSelected
                ? Border.all(
                    color: Colors.blueAccent.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 22,
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              Spacer(),
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}