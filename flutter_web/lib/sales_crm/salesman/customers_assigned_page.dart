import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';

class CustomersAssignedPage extends StatefulWidget {
  final int salesmanId;

  const CustomersAssignedPage({super.key, required this.salesmanId});

  @override
  State<CustomersAssignedPage> createState() => _CustomersAssignedPageState();
}

class _CustomersAssignedPageState extends State<CustomersAssignedPage> {
  late Future<List<dynamic>> _futureCustomers;

  @override
  void initState() {
    super.initState();
    _futureCustomers = UserApiService.fetchAssignedCustomers(widget.salesmanId);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customers Assigned to Me',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureCustomers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No customers assigned.', style: TextStyle(color: Colors.white)));
                }

                final customers = snapshot.data!;
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final c = customers[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.white),
                        title: Text('${c['first_name']} ${c['last_name']}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Email: ${c['email']}\nStatus: ${c['lead_status'] ?? 'N/A'} | Stage: ${c['pipeline_stage'] ?? 'N/A'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
