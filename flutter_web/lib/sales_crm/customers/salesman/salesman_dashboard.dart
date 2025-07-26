import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/customers/salesman/overview_page.dart';

class SalesmanDashboard extends StatefulWidget {
  final int salesmanId;

  const SalesmanDashboard({required this.salesmanId});

  @override
  _SalesmanDashboardState createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(OverviewPage(salesmanId: widget.salesmanId));
    // Add more pages like CustomerListPage, TasksPage, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Salesman",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 30),
                GlassNavButton(
                  label: "Overview",
                  icon: Icons.dashboard,
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                // Future: Add other navigation buttons here

                const Spacer(),
                GlassNavButton(
                  label: "Logout",
                  icon: Icons.logout,
                  selected: false,
                  onTap: () {
                    // TODO: handle logout
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Screen Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
    );
  }
}

// ✅ GlassNavButton (inline widget class)
class GlassNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const GlassNavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: Colors.white70, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
