import 'dart:ui';
import 'package:flutter/material.dart';
import '../../api/user_api_service.dart';

class CreateContactScreen extends StatefulWidget {
  final int companyId;
  const CreateContactScreen({super.key, required this.companyId});

  @override
  State<CreateContactScreen> createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  Map<int, TextEditingController> customFieldControllers = {};

  List<Map<String, dynamic>> salesmen = [];
  List<Map<String, dynamic>> lifecycleConfigs = [];
  List<Map<String, dynamic>> customFields = [];

  String? selectedUserId;
  String? selectedStage;
  String? selectedStatus;
  List<String> statusOptions = [];

  bool isSubmitting = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    try {
      final salesmenData = await UserApiService.getSalesmen(widget.companyId);
      final configsData = await UserApiService.getLifecycleConfigs(widget.companyId);
      final fieldData = await UserApiService.getCustomFields(widget.companyId);

      if (!mounted) return;
      setState(() {
        salesmen = salesmenData;
        lifecycleConfigs = configsData;
        customFields = fieldData;
        customFieldControllers = {
          for (var field in fieldData) field['id']: TextEditingController()
        };
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load data: ${e.toString()}";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    }
  }

  void _onStageSelected(String? stage) {
    if (stage == null) return;

    final stageConfig = lifecycleConfigs.firstWhere(
      (e) => e["stage"] == stage,
      orElse: () => {"stage": stage, "statuses": []},
    );

    final statuses = (stageConfig["statuses"] as List?)?.cast<String>() ?? [];

    setState(() {
      selectedStage = stage;
      selectedStatus = statuses.isNotEmpty ? null : selectedStatus;
      statusOptions = statuses;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please assign the contact to a salesman")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final contactData = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "email": _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        "contact_number": _phoneController.text.trim(),
        "pipeline_stage": selectedStage,
        "lead_status": selectedStatus,
        "assigned_to": int.parse(selectedUserId!),
        "company_id": widget.companyId,
      };

      final customerId = await UserApiService.createCustomer(contactData);
      if (customerId == null) throw Exception("Customer creation failed (null ID)");

      List<Map<String, dynamic>> customValuesPayload = [];
      customFieldControllers.forEach((fieldId, controller) {
        final val = controller.text.trim();
        if (val.isNotEmpty) {
          customValuesPayload.add({
            "customer_id": customerId,
            "field_id": fieldId,
            "value": val,
          });
        }
      });

      if (customValuesPayload.isNotEmpty) {
        await UserApiService.saveCustomValues(customValuesPayload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact created successfully!")),
      );
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      selectedUserId = null;
      selectedStage = null;
      selectedStatus = null;
      statusOptions = [];
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (var controller in customFieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
  extendBodyBehindAppBar: true,
  appBar: AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.of(context).pop(),
    ),
  ),
  body: Container(

        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
padding: const EdgeInsets.only(top: 60, bottom: 60),
  child: Container(

              width: screenWidth > 500 ? 500 : screenWidth * 0.9,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildFormContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Column(
        children: [
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadInitialData, child: const Text("Retry")),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Create Contact",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          _buildTextField("First Name", _firstNameController, isRequired: true),
          const SizedBox(height: 16),
          _buildTextField("Last Name", _lastNameController, isRequired: true),
          const SizedBox(height: 16),
          _buildTextField("Email", _emailController, inputType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField("Phone", _phoneController, inputType: TextInputType.phone, isRequired: true),
          const SizedBox(height: 16),
          _buildSalesmanDropdown(),
          const SizedBox(height: 16),
          _buildLifecycleStageDropdown(),
          const SizedBox(height: 16),
          _buildStatusDropdown(),
          const SizedBox(height: 24),

          if (customFields.isNotEmpty) ...[
            const Divider(),
            const Text("Custom Fields", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            ...customFields.map((field) {
              final id = field['id'] as int;
              final name = field['field_name'];
              final isRequired = field['is_required'] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildTextField(name, customFieldControllers[id]!, isRequired: isRequired),
              );
            }).toList(),
          ],

          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false, TextInputType? inputType}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        suffixIcon: isRequired
            ? const Icon(Icons.star, size: 12, color: Colors.redAccent)
            : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
    );
  }

  Widget _buildSalesmanDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedUserId,
      dropdownColor: Colors.black87,
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration("Assigned To *"),
      items: salesmen.map((salesman) {
        return DropdownMenuItem<String>(
          value: salesman["id"].toString(),
          child: Text(salesman["full_name"] ?? "Unknown", style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedUserId = value),
      validator: (value) => value == null ? "Please select a salesman" : null,
    );
  }

  Widget _buildLifecycleStageDropdown() {
    if (lifecycleConfigs.isEmpty) {
      return const Text("⚠️ No lifecycle stages configured.", style: TextStyle(color: Colors.white));
    }

    return DropdownButtonFormField<String>(
      value: selectedStage,
      dropdownColor: Colors.black87,
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration("Lifecycle Stage"),
      items: lifecycleConfigs.map((config) {
        return DropdownMenuItem<String>(
          value: config["stage"]?.toString(),
          child: Text(config["stage"]?.toString() ?? "No stage", style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: _onStageSelected,
    );
  }

  Widget _buildStatusDropdown() {
    if (statusOptions.isEmpty) {
      return const Text("⚠️ Select a stage to see statuses", style: TextStyle(color: Colors.white));
    }

    return DropdownButtonFormField<String>(
      value: selectedStatus,
      dropdownColor: Colors.black87,
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: _dropdownDecoration("Status"),
      items: statusOptions.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(status, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedStatus = value),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(isSubmitting ? "Creating..." : "Create Contact"),
        onPressed: isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
