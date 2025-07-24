// ignore: unused_import
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_web/sales_crm/api/user_api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';



class ReadContactsScreen extends StatefulWidget {
  final int companyId;
  const ReadContactsScreen({super.key, required this.companyId});

  @override
  State<ReadContactsScreen> createState() => _ReadContactsScreenState();
}

class _ReadContactsScreenState extends State<ReadContactsScreen> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> salesmen = [];
  List<Map<String, dynamic>> filteredContacts = [];

  int? selectedSalesmanId;
  bool isLoading = true;
  bool isError = false;
  String searchQuery = '';

  // Pagination
  int currentPage = 1;
  final int contactsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchSalesmen();
    fetchContacts();
  }

  Future<void> fetchSalesmen() async {
    try {
      final result = await UserApiService.getSalesmen(widget.companyId);
      setState(() => salesmen = result);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load salesmen")),
      );
    }
  }

  Future<void> fetchContacts() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final result = selectedSalesmanId == null
          ? await UserApiService.getAllCustomers(widget.companyId)
          : await UserApiService.getCustomersOfSalesman(selectedSalesmanId!);

      setState(() {
        contacts = result;
        _applySearch();
      });
    } catch (_) {
      setState(() => isError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applySearch() {
  setState(() {
    currentPage = 1;
    filteredContacts = contacts.where((contact) {
      final query = searchQuery.toLowerCase();
      final fullName = "${contact['first_name'] ?? ''} ${contact['last_name'] ?? ''}".toLowerCase();
      final email = (contact['email'] ?? '').toLowerCase();
      return fullName.contains(query) || email.contains(query);
    }).toList();
  });
}


  List<Map<String, dynamic>> get paginatedContacts {
    final start = (currentPage - 1) * contactsPerPage;
    final end = start + contactsPerPage;
    return filteredContacts.sublist(
      start,
      end > filteredContacts.length ? filteredContacts.length : end,
    );
  }

  Future<void> _exportToCSV() async {
  final headers = [
    "First Name",
    "Last Name",
    "Email",
    "Phone",
    "Company",
    "Pipeline Stage",
    "Lead Status",
    "Account Status",
    "Notes"
  ];

  final Set<String> customFieldNames = {};
  for (var contact in filteredContacts) {
    final customFields = contact["custom_fields"] ?? {};
    customFields.keys.forEach((key) {
      customFieldNames.add(key.toString());
    });
  }

  final allHeaders = [...headers, ...customFieldNames];
  final List<List<String>> rows = [allHeaders];

  for (var contact in filteredContacts) {
    final custom = contact["custom_fields"] ?? {};

    final row = [
      contact["first_name"]?.toString() ?? "",
      contact["last_name"]?.toString() ?? "",
      contact["email"]?.toString() ?? "",
      "'${contact["contact_number"]?.toString() ?? ""}",
      contact["company_name"]?.toString() ?? "",
      contact["pipeline_stage"]?.toString() ?? "",
      contact["lead_status"]?.toString() ?? "",
      contact["account_status"]?.toString() ?? "",
      contact["notes"]?.toString() ?? "",
    ];

    for (var field in customFieldNames) {
      row.add(custom[field]?.toString() ?? "");
    }

    rows.add(row);
  }

  final csvData = const ListToCsvConverter().convert(rows);
  final timestamp = DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-');
  final fileName = "contacts_export_$timestamp.csv";

  if (kIsWeb) {
    final bytes = Uint8List.fromList(utf8.encode(csvData));
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      mimeType: MimeType.csv,
    );
  } else {
    try {
      final dir = await getTemporaryDirectory();
      final file = io.File("${dir.path}/$fileName");
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported Contacts');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e")),
        );
      }
    }
  }
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
        title: const Text("All Contacts", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Container(
              width: screenWidth > 600 ? 700 : screenWidth * 0.9,
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
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (isError) {
      return const Center(child: Text("Failed to load contacts", style: TextStyle(color: Colors.white)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: "Search by name or email...",
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white54),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            searchQuery = val;
            _applySearch();
          },
        ),
        const SizedBox(height: 16),

        // Salesman Filter + Export Button
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedSalesmanId,
                dropdownColor: Colors.black87,
                iconEnabledColor: Colors.white,
                decoration: _dropdownDecoration("Filter by Salesman"),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Salesmen", style: TextStyle(color: Colors.white))),
                  ...salesmen.map((s) => DropdownMenuItem(
                        value: s["id"],
                        child: Text(s["full_name"], style: const TextStyle(color: Colors.white)),
                      )),
                ],
                onChanged: (value) {
                  setState(() => selectedSalesmanId = value);
                  fetchContacts();
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: filteredContacts.isEmpty ? null : _exportToCSV,
              icon: const Icon(Icons.download),
              label: const Text("Export"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (filteredContacts.isEmpty)
          const Text("No contacts found", style: TextStyle(color: Colors.white))
        else
          ...paginatedContacts.map((contact) {
            final _ = contact["custom_fields"] ?? {};
            return Card(
  color: Colors.white.withOpacity(0.9),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin: const EdgeInsets.only(bottom: 16),
  child: ExpansionTile(
    title: Text("${contact["first_name"] ?? ""} ${contact["last_name"] ?? ""}".trim()),
    subtitle: Text("${contact["email"] ?? "-"} | ${contact["contact_number"] ?? "-"}"),
    children: [
      ListTile(
        title: const Text("Company"),
        subtitle: Text(contact["company_name"] ?? "-"),
      ),
      ListTile(
        title: const Text("Pipeline Stage"),
        subtitle: Text(contact["pipeline_stage"] ?? "-"),
      ),
      ListTile(
        title: const Text("Lead Status"),
        subtitle: Text(contact["lead_status"] ?? "-"),
      ),
      ListTile(
        title: const Text("Account Status"),
        subtitle: Text(contact["account_status"] ?? "-"),
      ),
      ListTile(
        title: const Text("Notes"),
        subtitle: Text(contact["notes"] ?? "-"),
      ),
      if ((contact["custom_fields"] ?? {}).isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Custom Fields", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(contact["custom_fields"] as Map<String, dynamic>).entries.map(
                (entry) => Text("${entry.key}: ${entry.value}"),
              ),
            ],
          ),
        ),
    ],
  ),
);

          }),

        // Pagination Controls
        if (filteredContacts.length > contactsPerPage) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => setState(() => currentPage--)
                    : null,
              ),
              Text(
                "Page $currentPage / ${((filteredContacts.length - 1) / contactsPerPage).ceil()}",
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage * contactsPerPage < filteredContacts.length
                    ? () => setState(() => currentPage++)
                    : null,
              ),
            ],
          )
        ],
      ],
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
}
