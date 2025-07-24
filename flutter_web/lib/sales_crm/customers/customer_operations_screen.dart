import 'dart:ui';
import 'package:flutter/material.dart';
import 'crud/create_contact.dart';
import 'crud/read_contacts.dart';
import 'crud/update_contact.dart';
import 'crud/delete_contact.dart';

class CustomerOperationsScreen extends StatefulWidget {
  final int companyId;
  const CustomerOperationsScreen({super.key, required this.companyId});

  @override
  State<CustomerOperationsScreen> createState() => _CustomerOperationsScreenState();
}

class _CustomerOperationsScreenState extends State<CustomerOperationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color.fromARGB(255, 146, 170, 251),
      end: const Color.fromARGB(255, 36, 83, 121),
    ).animate(_controller);

    _color2 = ColorTween(
      begin: const Color.fromARGB(255, 100, 253, 228),
      end: const Color.fromARGB(255, 11, 67, 71),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<_CrudCard> operations = [];

  @override
  Widget build(BuildContext context) {
    operations.clear();
    operations.addAll([
      _CrudCard(
        title: "Create Contact",
        icon: Icons.person_add_alt_1,
        destination: CreateContactScreen(companyId: widget.companyId),
      ),
      _CrudCard(
        title: "Read Contacts",
        icon: Icons.view_list,
        destination: ReadContactsScreen(companyId: widget.companyId),
      ),
      _CrudCard(
        title: "Update Contact",
        icon: Icons.edit_note,
        destination: UpdateContactScreen(companyId: widget.companyId),
      ),
      _CrudCard(
        title: "Delete Contact",
        icon: Icons.delete_forever,
        destination: DeleteContactScreen(companyId: widget.companyId),
      ),
    ]);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Customer Operations"),
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
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  itemCount: operations.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, index) {
                    final op = operations[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          _fadeRoute(op.destination),
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
                                Icon(op.icon, size: 48, color: Colors.teal.shade800),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    op.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PageRouteBuilder _fadeRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
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
