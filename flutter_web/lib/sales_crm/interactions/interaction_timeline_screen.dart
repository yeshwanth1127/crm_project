import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/user_api_service.dart';

class InteractionTimelineScreen extends StatefulWidget {
  const InteractionTimelineScreen({super.key});

  @override
  State<InteractionTimelineScreen> createState() => _InteractionTimelineScreenState();
}

class _InteractionTimelineScreenState extends State<InteractionTimelineScreen> {
  int customerId = -1;
  bool isLoading = true;
  List<Map<String, dynamic>> interactions = [];

  @override
  void didChangeDependencies() {
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg != null && arg is int) {
      customerId = arg;
      fetchInteractions();
    }
    super.didChangeDependencies();
  }

  Future<void> fetchInteractions() async {
    setState(() => isLoading = true);
    try {
      final data = await UserApiService.getInteractionsByCustomer(customerId);
      setState(() {
        interactions = data;
      });
    } catch (e) {
      print('Error fetching interactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading interactions: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  
String formatTimestamp(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal(); // ✅ Convert to local time
    return DateFormat('MMM d, y – h:mm a').format(dt);
  } catch (_) {
    return raw;
  }
}

  Icon getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return const Icon(Icons.phone, color: Colors.blue);
      case 'email':
        return const Icon(Icons.email, color: Colors.red);
      case 'meeting':
        return const Icon(Icons.video_call, color: Colors.green);
      case 'whatsapp':
        return const Icon(Icons.message, color: Colors.teal);
      default:
        return const Icon(Icons.notes, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaction Timeline'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : interactions.isEmpty
              ? const Center(child: Text('No interactions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: interactions.length,
                  itemBuilder: (context, index) {
                    final i = interactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                getIcon(i['interaction_type'] ?? ''),
                                const SizedBox(width: 8),
                                Text(
                                  '${i['interaction_type']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (i['subtype'] != null) ...[
                                  const SizedBox(width: 6),
                                  Text('• ${i['subtype']}'),
                                ],
                                const Spacer(),
                                Text(formatTimestamp(i['timestamp'] ?? '')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (i['channel'] != null)
                              Text('Channel: ${i['channel']}'),
                            if (i['outcome'] != null)
                              Text('Outcome: ${i['outcome']}'),
                            if (i['visibility'] != null)
                              Text('Visibility: ${i['visibility']}'),
                            if (i['content'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                i['content'],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                            if (i['next_steps'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Next Steps: ${i['next_steps']}',
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              )
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
