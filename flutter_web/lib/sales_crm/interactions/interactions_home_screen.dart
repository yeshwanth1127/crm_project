import 'package:flutter/material.dart';
import '../api/user_api_service.dart';

class InteractionsHomeScreen extends StatefulWidget {
  const InteractionsHomeScreen({super.key});

  @override
  State<InteractionsHomeScreen> createState() => _InteractionsHomeScreenState();
}

class _InteractionsHomeScreenState extends State<InteractionsHomeScreen> {
  List<Map<String, dynamic>> salesmen = [];
  List<Map<String, dynamic>> customers = [];
  int? selectedSalesmanId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSalesmenAndCustomers();
  }

  Future<void> fetchSalesmenAndCustomers() async {
    try {
      final companyId = await UserApiService.getCompanyId(); // implement if needed
      final s = await UserApiService.getUsersByRole(companyId, 'salesman');
      final c = await UserApiService.getCustomersByCompany(companyId);

      setState(() {
        salesmen = s;
        customers = c;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> filterBySalesman(int? salesmanId) async {
    try {
      setState(() {
        isLoading = true;
        selectedSalesmanId = salesmanId;
      });

      if (salesmanId == null) {
        final companyId = await UserApiService.getCompanyId();
        final all = await UserApiService.getCustomersByCompany(companyId);
        setState(() => customers = all);
      } else {
        final filtered = await UserApiService.getCustomersBySalesman(salesmanId);
        setState(() => customers = filtered);
      }
    } catch (e) {
      print('Filter error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void navigateToLogInteraction(int customerId) {
    Navigator.pushNamed(context, '/log-interaction', arguments: customerId);
  }

  void navigateToTimeline(int customerId) {
    Navigator.pushNamed(context, '/interaction-timeline', arguments: customerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactions'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: selectedSalesmanId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Salesman',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Salesmen'),
                      ),
                      ...salesmen.map((s) => DropdownMenuItem(
                            value: s['id'],
                            child: Text(s['full_name']),
                          ))
                    ],
                    onChanged: (val) => filterBySalesman(val),
                  ),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? const Center(child: Text('No customers found.'))
                      : ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${customer['first_name']} ${customer['last_name']}',
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Phone: ${customer['contact_number'] ?? 'N/A'}'),
                                    Text('Email: ${customer['email'] ?? 'N/A'}'),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => navigateToLogInteraction(customer['id']),
                                          icon: const Icon(Icons.note_add),
                                          label: const Text('Log Interaction'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => navigateToTimeline(customer['id']),
                                          icon: const Icon(Icons.timeline),
                                          label: const Text('View Timeline'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
