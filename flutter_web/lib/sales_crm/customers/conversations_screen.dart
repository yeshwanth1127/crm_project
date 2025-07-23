import 'package:flutter/material.dart';
import '../api/user_api_service.dart';

class ConversationsScreen extends StatefulWidget {
  final int companyId;
  const ConversationsScreen({super.key, required this.companyId});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String selectedChannel = 'email';
  String selectedDirection = 'outbound';
  bool isLoading = false;
  bool isSending = false;

  List<Map<String, dynamic>> conversations = [];

  Future<void> loadConversations() async {
    final id = int.tryParse(_customerIdController.text.trim());
    if (id == null) return;

    setState(() {
      isLoading = true;
      conversations.clear();
    });

    try {
      final result = await UserApiService.getConversations(id);
      setState(() => conversations = result);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load conversations")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendConversation() async {
    final id = int.tryParse(_customerIdController.text.trim());
    final message = _messageController.text.trim();
    if (id == null || message.isEmpty) return;

    setState(() => isSending = true);

    try {
      await UserApiService.logConversation(
        customerId: id,
        channel: selectedChannel,
        direction: selectedDirection,
        message: message,
      );
      _messageController.clear();
      await loadConversations();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Conversations"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Enter Customer ID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: loadConversations, child: const Text("Load")),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedChannel,
                    items: const [
                      DropdownMenuItem(value: 'email', child: Text("Email")),
                      DropdownMenuItem(value: 'sms', child: Text("SMS")),
                      DropdownMenuItem(value: 'call', child: Text("Call")),
                      DropdownMenuItem(value: 'social', child: Text("Social")),
                    ],
                    onChanged: (val) => setState(() => selectedChannel = val!),
                    decoration: const InputDecoration(labelText: "Channel", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDirection,
                    items: const [
                      DropdownMenuItem(value: 'outbound', child: Text("Outbound")),
                      DropdownMenuItem(value: 'inbound', child: Text("Inbound")),
                    ],
                    onChanged: (val) => setState(() => selectedDirection = val!),
                    decoration: const InputDecoration(labelText: "Direction", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: Text(isSending ? "Sending..." : "Send Conversation"),
                onPressed: isSending ? null : sendConversation,
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : conversations.isEmpty
                      ? const Center(child: Text("No conversations found"))
                      : ListView.builder(
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final convo = conversations[index];
                            return Card(
                              child: ListTile(
                                title: Text("${convo['channel']} • ${convo['direction']}"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(convo['message']),
                                    const SizedBox(height: 4),
                                    Text("Time: ${convo['timestamp']}", style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: convo['is_read'] == true
                                    ? const Icon(Icons.mark_email_read, color: Colors.green)
                                    : const Icon(Icons.mark_email_unread, color: Colors.orange),
                              ),
                            );
                          },
                        ),
            )
          ],
        ),
      ),
    );
  }
}
