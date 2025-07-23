import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';

class ReadContactsScreen extends StatefulWidget {
  final int companyId;
  const ReadContactsScreen({super.key, required this.companyId});

  @override
  State<ReadContactsScreen> createState() => _ReadContactsScreenState();
}

class _ReadContactsScreenState extends State<ReadContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> salesmen = [];
  int? selectedSalesmanId;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchSalesmen();
    fetchContacts(); // load full list initially
  }

  Future<void> fetchSalesmen() async {
    try {
      final result = await UserApiService.getSalesmen(widget.companyId);
      setState(() => salesmen = result);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load salesmen")),
      );
    }
  }

  Future<void> fetchContacts() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final result = selectedSalesmanId == null
          ? await UserApiService.getAllCustomers(widget.companyId)
          : await UserApiService.getCustomersOfSalesman(selectedSalesmanId!);

      setState(() => contacts = result);
    } catch (_) {
      setState(() => isError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Contacts"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
              ? const Center(child: Text("Failed to load contacts"))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        value: selectedSalesmanId,
                        decoration: const InputDecoration(
                          labelText: "Filter by Salesman",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Salesmen")),
                          ...salesmen.map((s) => DropdownMenuItem(
                                value: s["id"],
                                child: Text(s["full_name"]),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => selectedSalesmanId = value);
                          fetchContacts();
                        },
                      ),
                    ),
                    Expanded(
                      child: contacts.isEmpty
                          ? const Center(child: Text("No contacts found"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                final customFields = contact["custom_fields"] ?? {};

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ExpansionTile(
                                    title: Text(contact["name"] ?? "Unnamed"),
                                    subtitle: Text(
                                        "${contact["email"] ?? "-"} | ${contact["contact_number"] ?? "-"}"),
                                    children: [
                                      ListTile(
                                        title: const Text("Company"),
                                        subtitle: Text(contact["company_name"] ?? "-"),
                                      ),
                                      ListTile(
                                        title: const Text("Pipeline Stage"),
                                        subtitle: Text(contact["pipeline_stage"] ?? "-"),
                                      ),
                                      ListTile(
                                        title: const Text("Lead Status"),
                                        subtitle: Text(contact["lead_status"] ?? "-"),
                                      ),
                                      if (customFields.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Custom Fields",
                                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              ...customFields.entries.map(
                                                (entry) => Text("${entry.key}: ${entry.value}"),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
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
