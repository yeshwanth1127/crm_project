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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();

  List<Map<String, dynamic>> salesmen = [];
  List<Map<String, dynamic>> customers = [];
  Map<String, dynamic> selectedCustomer = {};

  Map<String, dynamic> customFieldValues = {};
  List<Map<String, dynamic>> customFields = [];

  int? selectedSalesmanId;
  int? selectedCustomerId;

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchSalesmen();
  }

  Future<void> fetchSalesmen() async {
    try {
      final result = await UserApiService.getSalesmen(widget.companyId);
      setState(() => salesmen = result);
    } catch (_) {}
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
      selectedCustomerId = null;
      selectedCustomer = {};
    });

    try {
      final result = selectedSalesmanId == null
          ? await UserApiService.getAllCustomers(widget.companyId)
          : await UserApiService.getCustomersOfSalesman(selectedSalesmanId!);
      setState(() => customers = result);
    } catch (_) {}
    setState(() => isLoading = false);
  }

  Future<void> loadCustomerDetails(int id) async {
    setState(() => isLoading = true);

    try {
      final customer = await UserApiService.getCustomerById(id);
      final fields = await UserApiService.getCustomFields(widget.companyId);

      setState(() {
        _firstNameController.text = customer["first_name"] ?? "";
        _lastNameController.text = customer["last_name"] ?? "";
        _emailController.text = customer["email"] ?? "";
        _phoneController.text = customer["contact_number"] ?? "";
        _companyController.text = customer["company_name"] ?? "";

        customFields = fields;
        final rawFields = customer["custom_fields"] ?? [];
        customFieldValues = {
          for (var f in rawFields)
            if (f["field_name"] != null) f["field_name"]: f["value"]
        };

        selectedCustomer = customer;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load customer details")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    final id = selectedCustomerId;
    if (id == null) return;

    setState(() => isSubmitting = true);

    final updatePayload = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "contact_number": _phoneController.text.trim(),
      "company_name": _companyController.text.trim(),
    };

    try {
      final success = await UserApiService.updateCustomer(id, updatePayload);

      if (success && customFields.isNotEmpty) {
        final values = customFields.map((field) {
          final fieldName = field["field_name"];
          return {
            "customer_id": id,
            "field_id": field["id"],
            "value": customFieldValues[fieldName] ?? "",
          };
        }).toList();
        await UserApiService.saveCustomFieldValues(values);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer updated")),
      );
    } catch (e) {
  print("Update failed: $e");
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Update failed: $e")),
  );
}

    setState(() => isSubmitting = false);
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
            DropdownButtonFormField<int>(
              value: selectedSalesmanId,
              decoration: const InputDecoration(labelText: "Filter by Salesman"),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text("All Salesmen")),
                ...salesmen.map<DropdownMenuItem<int>>((s) => DropdownMenuItem<int>(
                      value: s["id"] as int,
                      child: Text(s["full_name"]),
                    )),
              ],
              onChanged: (val) {
                setState(() => selectedSalesmanId = val);
                fetchCustomers();
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: selectedCustomerId,
              decoration: const InputDecoration(labelText: "Select Customer"),
              items: customers.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c["id"] as int,
                  child: Text("${c["first_name"]} ${c["last_name"]} (${c["email"]})"),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedCustomerId = val);
                  loadCustomerDetails(val);
                }
              },
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const CircularProgressIndicator()
            else if (selectedCustomer.isNotEmpty)
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildField("First Name", _firstNameController, TextInputType.name),
                      const SizedBox(height: 16),
                      _buildField("Last Name", _lastNameController, TextInputType.name),
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
