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
  List<Map<String, dynamic>> customFields = [];
  Map<int, TextEditingController> customControllers = {};
  Map<int, TextEditingController> customFieldControllers = {};


  List<Map<String, dynamic>> salesmen = [];
  List<Map<String, dynamic>> lifecycleConfigs = [];

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      late List<Map<String, dynamic>> salesmenData;
late List<Map<String, dynamic>> configsData;
late List<Map<String, dynamic>> fieldData;

try {
  salesmenData = await UserApiService.getSalesmen(widget.companyId);
  configsData = await UserApiService.getLifecycleConfigs(widget.companyId);
  fieldData = await UserApiService.getCustomFields(widget.companyId);
} catch (e) {
  if (mounted) {
    setState(() {
      isLoading = false;
      errorMessage = "Failed to load data: ${e.toString()}";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage!)),
    );
    return;
  }
}

if (mounted) {
  setState(() {
    salesmen = salesmenData;
    lifecycleConfigs = configsData;
    customFields = fieldData;
    customFieldControllers = {
      for (var field in fieldData) field['id']: TextEditingController()
    };
    isLoading = false;
  });
}


      if (mounted) {
        setState(() {
  salesmen = salesmenData;
  lifecycleConfigs = configsData;
  customFields = customFields;
  customControllers = {
    for (var field in customFields) field['id']: TextEditingController()
  };
  isLoading = false;
});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load data: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
      }
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
    // Prepare contact data
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

    // Attempt to create customer and receive customer_id
    final customerId = await UserApiService.createCustomer(contactData);

    if (customerId == null) {
      throw Exception("Customer creation failed (null ID)");
    }

    // Prepare custom field values
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

    // Save custom field values (only if any)
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Contact"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
  padding: const EdgeInsets.all(24),
  child: Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Dynamic Custom Fields
        if (customFields.isNotEmpty) ...[
          const Divider(),
          const Text("Custom Fields", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...customFields.map((field) {
            final id = field['id'] as int;
            final name = field['field_name'];
            final isRequired = field['is_required'] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTextField(
                name,
                customFieldControllers[id]!,
                isRequired: isRequired,
              ),
            );
          }).toList(),
        ],

        _buildSubmitButton(),
      ],
    ),
  ),
);


  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = false, TextInputType? inputType}) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: isRequired ? const Icon(Icons.star, size: 12, color: Colors.red) : null,
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
      decoration: const InputDecoration(
        labelText: "Assigned To*",
        border: OutlineInputBorder(),
      ),
      items: salesmen.map((salesman) {
        return DropdownMenuItem<String>(
          value: salesman["id"].toString(),
          child: Text(salesman["full_name"]?.toString() ?? 'Unknown Salesman'),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedUserId = value),
      validator: (value) => value == null ? "Please select a salesman" : null,
      hint: const Text("Select salesman"),
    );
  }

  Widget _buildLifecycleStageDropdown() {
  if (lifecycleConfigs.isEmpty) {
    return const Text("⚠️ No lifecycle stages configured. Please add some.");
  }

  return DropdownButtonFormField<String>(
    value: selectedStage,
    decoration: const InputDecoration(
      labelText: "Lifecycle Stage",
      border: OutlineInputBorder(),
    ),
    items: lifecycleConfigs.map((config) {
      return DropdownMenuItem<String>(
        value: config["stage"]?.toString(),
        child: Text(config["stage"]?.toString() ?? 'No stage'),
      );
    }).toList(),
    onChanged: _onStageSelected,
    hint: const Text("Select stage (optional)"),
  );
}
Widget _buildStatusDropdown() {
  if (statusOptions.isEmpty) {
    return const Text("⚠️ Select a stage to see statuses");
  }

  return DropdownButtonFormField<String>(
    value: selectedStatus,
    decoration: const InputDecoration(
      labelText: "Status",
      border: OutlineInputBorder(),
    ),
    items: statusOptions.map((status) {
      return DropdownMenuItem<String>(
        value: status,
        child: Text(status),
      );
    }).toList(),
    onChanged: (value) => setState(() => selectedStatus = value),
    hint: const Text("Select status"),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}