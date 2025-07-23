import 'package:flutter/material.dart';
import 'customer_operations_screen.dart';
import 'custom_fields_screen.dart';
import 'lifecycle_config_screen.dart';
import 'sync_contacts_screen.dart';
import 'conversations_screen.dart';
import 'inbox_integration_screen.dart';

class CustomersHome extends StatelessWidget {
  final int companyId;
  const CustomersHome({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final List<_FeatureCard> features = [
      _FeatureCard(
        title: "Customer Operations",
        icon: Icons.people,
        destination: CustomerOperationsScreen(companyId: companyId),
      ),
      _FeatureCard(
        title: "Add Custom Fields",
        icon: Icons.settings,
        destination: CustomFieldsScreen(companyId: companyId),
      ),
      _FeatureCard(
        title: "Lifecycle & Status Config",
        icon: Icons.timeline,
        destination: LifecycleConfigScreen(companyId: companyId),
      ),
      _FeatureCard(
        title: "Sync Contact Data",
        icon: Icons.sync_alt,
        destination: SyncContactsScreen(companyId: companyId),
      ),
      _FeatureCard(
        title: "Conversations",
        icon: Icons.chat_outlined,
        destination: ConversationsScreen(companyId: companyId),
      ),
      _FeatureCard(
        title: "Inbox Integration",
        icon: Icons.inbox_outlined,
        destination: InboxIntegrationScreen(companyId: companyId),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Management"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          children: features.map((feature) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => feature.destination),
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(feature.icon, size: 48, color: Colors.blue.shade600),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          feature.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FeatureCard {
  final String title;
  final IconData icon;
  final Widget destination;

  _FeatureCard({
    required this.title,
    required this.icon,
    required this.destination,
  });
}
