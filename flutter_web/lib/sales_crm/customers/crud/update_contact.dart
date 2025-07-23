import 'package:flutter/material.dart';
import '../../api/user_api_service.dart';

class UpdateContactScreen extends StatefulWidget {
  final int companyId;
  const UpdateContactScreen({super.key, required this.companyId});

  @override
  State<UpdateContactScreen> createState() => _UpdateContactScreenState();
}

class _UpdateContactScreenState extends State<UpdateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();

  Map<String, dynamic> customFieldValues = {};
  List<Map<String, dynamic>> customFields = [];

  bool isLoading = false;
  bool isSubmitting = false;
  bool customerLoaded = false;

  Future<void> loadCustomer() async {
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() {
      isLoading = true;
      customerLoaded = false;
    });

    try {
      final customer = await UserApiService.getCustomerById(id);
      final fields = await UserApiService.getCustomFields(widget.companyId);

      setState(() {
        _nameController.text = customer["name"] ?? "";
        _emailController.text = customer["email"] ?? "";
        _phoneController.text = customer["contact_number"] ?? "";
        _companyController.text = customer["company_name"] ?? "";

        customFields = fields;
        customFieldValues = Map<String, dynamic>.from(customer["custom_fields"] ?? {});
        customerLoaded = true;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer not found")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    final id = int.tryParse(_idController.text.trim());
    if (id == null) return;

    setState(() => isSubmitting = true);

    final updatePayload = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "contact_number": _phoneController.text.trim(),
      "company_name": _companyController.text.trim(),
    };

    try {
      final success = await UserApiService.updateCustomer(id, updatePayload);

      // Save custom fields if any
      if (success && customFields.isNotEmpty) {
        final values = customFields.map((field) {
          final fieldName = field["field_name"];
          final fieldId = field["id"];
          return {
            "customer_id": id,
            "field_id": fieldId,
            "value": customFieldValues[fieldName] ?? "",
          };
        }).toList();
        await UserApiService.saveCustomFieldValues(values);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer updated")),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Contact"),
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
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator()
            else if (customerLoaded)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildField("Name", _nameController, TextInputType.name),
                      const SizedBox(height: 16),
                      _buildField("Email", _emailController, TextInputType.emailAddress, isEmail: true),
                      const SizedBox(height: 16),
                      _buildField("Phone", _phoneController, TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildField("Company Name", _companyController, TextInputType.text),
                      const SizedBox(height: 24),
                      if (customFields.isNotEmpty)
                        ...customFields.map((field) {
                          final key = field["field_name"];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              initialValue: customFieldValues[key] ?? "",
                              decoration: InputDecoration(
                                labelText: key,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (val) => customFieldValues[key] = val,
                            ),
                          );
                        }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : submitUpdate,
                          icon: const Icon(Icons.update),
                          label: Text(isSubmitting ? "Updating..." : "Update Contact"),
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

  Widget _buildField(String label, TextEditingController controller, TextInputType type,
      {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Enter valid email";
        return null;
      },
    );
  }
}
