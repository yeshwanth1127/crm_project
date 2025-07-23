import 'package:flutter/material.dart';
import 'crud/create_contact.dart';
import 'crud/read_contacts.dart';
import 'crud/update_contact.dart';
import 'crud/delete_contact.dart';

class CustomerOperationsScreen extends StatelessWidget {
  final int companyId;
  const CustomerOperationsScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final List<_CrudCard> operations = [
      _CrudCard(
        title: "Create Contact",
        icon: Icons.person_add_alt_1,
        destination: CreateContactScreen(companyId: companyId),
      ),
      _CrudCard(
        title: "Read Contacts",
        icon: Icons.view_list,
        destination: ReadContactsScreen(companyId: companyId),
      ),
      _CrudCard(
        title: "Update Contact",
        icon: Icons.edit_note,
        destination: UpdateContactScreen(companyId: companyId),
      ),
      _CrudCard(
        title: "Delete Contact",
        icon: Icons.delete_forever,
        destination: DeleteContactScreen(companyId: companyId),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Operations"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          children: operations.map((op) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => op.destination),
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(op.icon, size: 48, color: Colors.teal.shade700),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          op.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CrudCard {
  final String title;
  final IconData icon;
  final Widget destination;

  _CrudCard({
    required this.title,
    required this.icon,
    required this.destination,
  });
}
