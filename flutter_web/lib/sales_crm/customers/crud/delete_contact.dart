import 'package:flutter/material.dart';
import '../../api/user_api_service.dart';

class DeleteContactScreen extends StatefulWidget {
  final int companyId;
  const DeleteContactScreen({super.key, required this.companyId});

  @override
  State<DeleteContactScreen> createState() => _DeleteContactScreenState();
}

class _DeleteContactScreenState extends State<DeleteContactScreen> {
  final TextEditingController _idController = TextEditingController();

  Map<String, dynamic>? customer;
  bool isLoading = false;
  bool isDeleting = false;

  Future<void> loadCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() {
      isLoading = true;
      customer = null;
    });

    try {
      final result = await UserApiService.getCustomerById(id);
      setState(() => customer = result);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer not found")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() => isDeleting = true);

    try {
      final success = await UserApiService.deleteCustomer(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer deleted")),
        );
        setState(() {
          customer = null;
          _idController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete customer")),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred during deletion")),
      );
    } finally {
      setState(() => isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Contact"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Customer ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: loadCustomer,
                  child: const Text("Load"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (customer != null)
              Card(
                elevation: 3,
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${customer!['name']}"),
                      Text("Email: ${customer!['email']}"),
                      Text("Phone: ${customer!['contact_number']}"),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: Text(isDeleting ? "Deleting..." : "Confirm Delete"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: isDeleting ? null : deleteCustomer,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
