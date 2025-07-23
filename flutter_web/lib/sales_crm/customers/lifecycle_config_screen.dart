import 'package:flutter/material.dart';
import '../api/user_api_service.dart';

class LifecycleConfigScreen extends StatefulWidget {
  final int companyId;
  const LifecycleConfigScreen({super.key, required this.companyId});

  @override
  State<LifecycleConfigScreen> createState() => _LifecycleConfigScreenState();
}

class _LifecycleConfigScreenState extends State<LifecycleConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _stageController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  List<String> statusList = [];
  List<Map<String, dynamic>> existingConfigs = [];

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchConfigs();
  }

  Future<void> fetchConfigs() async {
    try {
      final configs = await UserApiService.getLifecycleConfigs(widget.companyId);
      setState(() => existingConfigs = configs);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch configs")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitConfig() async {
    if (!_formKey.currentState!.validate()) return;
if (statusList.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please add at least one status.")),
  );
  return;
}

    final payload = {
      "company_id": widget.companyId,
      "stage": _stageController.text.trim(),
      "statuses": statusList,
    };

    setState(() => isSubmitting = true);
    try {
      await UserApiService.createLifecycleConfig(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lifecycle config added")),
      );
      _formKey.currentState!.reset();
      setState(() {
        statusList.clear();
      });
      await fetchConfigs();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save config")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void addStatus() {
    final text = _statusController.text.trim();
    if (text.isNotEmpty && !statusList.contains(text)) {
      setState(() {
        statusList.add(text);
        _statusController.clear();
      });
    }
  }

  void removeStatus(String value) {
    setState(() {
      statusList.remove(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lifecycle & Status Config"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _stageController,
                          decoration: const InputDecoration(
                            labelText: "Lifecycle Stage (e.g., Lead)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _statusController,
                                decoration: const InputDecoration(
                                  labelText: "Add Status (e.g., Warm)",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: addStatus,
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: statusList
                              .map((s) => Chip(
                                    label: Text(s),
                                    onDeleted: () => removeStatus(s),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : submitConfig,
                            icon: const Icon(Icons.save),
                            label: Text(isSubmitting ? "Saving..." : "Save Config"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 40),
                  Expanded(
                    child: ListView.builder(
                      itemCount: existingConfigs.length,
                      itemBuilder: (context, index) {
                        final item = existingConfigs[index];
                        return Card(
                          child: ListTile(
                            title: Text(item["stage"]),
                            subtitle: Text("Statuses: ${item["statuses"].join(', ')}"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
