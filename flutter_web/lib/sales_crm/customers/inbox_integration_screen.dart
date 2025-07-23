import 'package:flutter/material.dart';

class InboxIntegrationScreen extends StatefulWidget {
  final int companyId;
  const InboxIntegrationScreen({super.key, required this.companyId});

  @override
  State<InboxIntegrationScreen> createState() => _InboxIntegrationScreenState();
}

class _InboxIntegrationScreenState extends State<InboxIntegrationScreen> {
  String? connectedProvider;
  bool isConnecting = false;

  void connectInbox(String provider) async {
    setState(() {
      isConnecting = true;
    });

    await Future.delayed(const Duration(seconds: 1)); // Simulate API/OAuth call

    setState(() {
      connectedProvider = provider;
      isConnecting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$provider connected successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inbox Integration"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Connect a shared inbox:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _inboxOption("Gmail", Icons.mail, Colors.red),
                _inboxOption("Outlook", Icons.email, Colors.blue.shade600),
                _inboxOption("IMAP (Custom)", Icons.settings, Colors.teal),
              ],
            ),
            const SizedBox(height: 40),
            if (connectedProvider != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Text(
                      "$connectedProvider inbox is connected",
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _inboxOption(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      icon: Icon(icon),
      label: Text("Connect $label"),
      onPressed: isConnecting ? null : () => connectInbox(label),
    );
  }
}
