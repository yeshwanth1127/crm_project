import 'dart:ui';
import 'package:flutter/material.dart';

class CustomerListPage extends StatefulWidget {
  final List<dynamic> customers;

  const CustomerListPage({super.key, required this.customers});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final Set<int> _expandedCustomerIds = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customers Assigned to Your Team',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: widget.customers.map((c) => _buildCustomerCard(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(dynamic c) {
    final isExpanded = _expandedCustomerIds.contains(c['id']);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCustomerIds.remove(c['id']);
          } else {
            _expandedCustomerIds.add(c['id']);
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${c['first_name']} ${c['last_name']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text("Stage: ${c['pipeline_stage'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70)),
                Text("Status: ${c['lead_status'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70)),
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white30),
                  Text("Email: ${c['email'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Phone: ${c['contact_number'] ?? 'N/A'}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Account Status: ${c['account_status'] ?? 'Active'}",
                      style: const TextStyle(color: Colors.white70)),
                  Text("Assigned To: ${c['assigned_to'] ?? 'Unassigned'}",
                      style: const TextStyle(color: Colors.white70)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
