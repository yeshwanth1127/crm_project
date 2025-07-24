import 'package:flutter/material.dart';
import '../api/user_api_service.dart';

class LogInteractionFormScreen extends StatefulWidget {
  const LogInteractionFormScreen({super.key});

  @override
  State<LogInteractionFormScreen> createState() => _LogInteractionFormScreenState();
}

class _LogInteractionFormScreenState extends State<LogInteractionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? interactionType;
  String? subtype;
  String? channel;
  String? outcome;
  String visibility = 'public';
  String? content;
  String? nextSteps;

  final List<String> interactionTypes = ['Call', 'Email', 'Meeting', 'WhatsApp', 'Social Media'];
  final Map<String, List<String>> subtypesMap = {
    'Call': ['Inbound', 'Outbound', 'Missed'],
    'Email': ['Inbound', 'Outbound', 'Marketing'],
    'Meeting': ['Demo', 'Negotiation', 'Training'],
    'WhatsApp': ['Customer-Initiated', 'Rep-Initiated'],
    'Social Media': ['Instagram', 'LinkedIn', 'Facebook'],
  };

  bool isSubmitting = false;

  int customerId = -1;

  @override
  void didChangeDependencies() {
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg != null && arg is int) {
      customerId = arg;
    }
    super.didChangeDependencies();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isSubmitting = true);

    try {
      final Map<String, dynamic> data = {
        'customer_id': customerId,
        'interaction_type': interactionType,
        'subtype': subtype,
        'channel': channel,
        'outcome': outcome,
        'visibility': visibility,
        'content': content,
        'next_steps': nextSteps,
      };

      await UserApiService.logInteraction(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interaction logged successfully')),
      );

      Navigator.pushReplacementNamed(context, '/interaction-timeline', arguments: customerId);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log interaction: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtypes = interactionType != null ? subtypesMap[interactionType!] ?? [] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Interaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Interaction Type'),
                value: interactionType,
                items: interactionTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    interactionType = value;
                    subtype = null;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              if (subtypes.isNotEmpty)
                DropdownButtonFormField<String>(
  decoration: const InputDecoration(labelText: 'Subtype'),
  value: subtype,
  items: subtypes
      .map<DropdownMenuItem<String>>(
        (type) => DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        ),
      )
      .toList(),
  onChanged: (value) => setState(() => subtype = value),
),

              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Channel'),
                onSaved: (val) => channel = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Outcome'),
                onSaved: (val) => outcome = val,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Visibility'),
                value: visibility,
                items: const [
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                ],
                onChanged: (value) => setState(() => visibility = value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes / Content'),
                maxLines: 3,
                onSaved: (val) => content = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Next Steps'),
                onSaved: (val) => nextSteps = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitForm,
                icon: const Icon(Icons.save),
                label: isSubmitting
                    ? const Text('Submitting...')
                    : const Text('Submit Interaction'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
