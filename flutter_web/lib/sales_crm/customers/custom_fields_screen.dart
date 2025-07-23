import 'package:flutter/material.dart';
import '../api/user_api_service.dart';

class CustomFieldsScreen extends StatefulWidget {
  final int companyId;
  const CustomFieldsScreen({super.key, required this.companyId});

  @override
  State<CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<CustomFieldsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fieldNameController = TextEditingController();

  String selectedFieldType = "text";
  bool isRequired = false;
  bool isSubmitting = false;

  final List<String> fieldTypes = ["text", "number", "date", "dropdown"];

  Future<void> _submitCustomField() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "company_id": widget.companyId,
      "field_name": _fieldNameController.text.trim(),
      "field_type": selectedFieldType,
      "is_required": isRequired,
    };

    setState(() => isSubmitting = true);

    try {
      await UserApiService.createCustomField(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Custom field added successfully")),
      );
      _formKey.currentState!.reset();
      setState(() {
        selectedFieldType = "text";
        isRequired = false;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add custom field")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Custom Fields"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _fieldNameController,
                decoration: const InputDecoration(
                  labelText: "Field Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? "Field name required" : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedFieldType,
                items: fieldTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.toUpperCase())))
                    .toList(),
                onChanged: (value) => setState(() => selectedFieldType = value!),
                decoration: const InputDecoration(
                  labelText: "Field Type",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text("Is Required?"),
                value: isRequired,
                onChanged: (val) => setState(() => isRequired = val!),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(isSubmitting ? "Adding..." : "Add Custom Field"),
                  onPressed: isSubmitting ? null : _submitCustomField,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
