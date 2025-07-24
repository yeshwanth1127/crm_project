import 'dart:ui';
import 'package:flutter/material.dart';
import 'customer_operations_screen.dart';
import 'custom_fields_screen.dart';
import 'lifecycle_config_screen.dart';
import 'sync_contacts_screen.dart';
import 'conversations_screen.dart';
import 'inbox_integration_screen.dart';

class CustomersHome extends StatefulWidget {
  final int companyId;
  const CustomersHome({super.key, required this.companyId});

  @override
  State<CustomersHome> createState() => _CustomersHomeState();
}

class _CustomersHomeState extends State<CustomersHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);

    _color1 = ColorTween(begin: Colors.blue.shade300, end: Colors.purple.shade200)
        .animate(_controller);
    _color2 = ColorTween(begin: Colors.pink.shade100, end: Colors.orange.shade200)
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<_FeatureCard> features = [];

  @override
  Widget build(BuildContext context) {
    features.clear();
    features.addAll([
      _FeatureCard(
        title: "Customer Operations",
        imageAsset: 'assets/images/customers.png',
        destination: CustomerOperationsScreen(companyId: widget.companyId),
      ),
      _FeatureCard(
        title: "Add Custom Fields",
        imageAsset: 'assets/images/custom_fields.png',
        destination: CustomFieldsScreen(companyId: widget.companyId),
      ),
      _FeatureCard(
        title: "Lifecycle & Status Config",
        imageAsset: 'assets/images/lifecycle.png',
        destination: LifecycleConfigScreen(companyId: widget.companyId),
      ),
      _FeatureCard(
        title: "Sync Contact Data",
        imageAsset: 'assets/images/sync.png',
        destination: SyncContactsScreen(companyId: widget.companyId),
      ),
      _FeatureCard(
        title: "Conversations",
        imageAsset: 'assets/images/chat.png',
        destination: ConversationsScreen(companyId: widget.companyId),
      ),
      _FeatureCard(
        title: "Inbox Integration",
        imageAsset: 'assets/images/inbox.png',
        destination: InboxIntegrationScreen(companyId: widget.companyId),
      ),
    ]);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Customer Management"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color1.value!, _color2.value!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      itemCount: features.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => feature.destination,
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      feature.imageAsset,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        feature.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard {
  final String title;
  final String imageAsset;
  final Widget destination;

  _FeatureCard({
    required this.title,
    required this.imageAsset,
    required this.destination,
  });
}
