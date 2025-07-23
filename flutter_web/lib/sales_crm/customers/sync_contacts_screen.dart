import 'package:flutter/material.dart';

class SyncContactsScreen extends StatelessWidget {
  final int companyId;
  const SyncContactsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Contact Data"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sync your CRM with external contact sources:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _syncOption(
              label: "Sync with Gmail",
              icon: Icons.mail_outline,
              color: Colors.red,
              onPressed: () => _showComingSoon(context, "Gmail Sync"),
            ),
            const SizedBox(height: 20),
            _syncOption(
              label: "Sync with Outlook",
              icon: Icons.email_outlined,
              color: Colors.blue,
              onPressed: () => _showComingSoon(context, "Outlook Sync"),
            ),
            const SizedBox(height: 20),
            _syncOption(
              label: "Manual Import (CSV, Excel)",
              icon: Icons.upload_file,
              color: Colors.grey,
              onPressed: () => _showComingSoon(context, "Manual Import"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncOption({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature coming soon")),
    );
  }
}
