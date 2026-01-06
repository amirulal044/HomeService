import 'package:flutter/material.dart';
import 'admin_mitra_page.dart';
import 'admin_order_page.dart';
import 'admin_profil_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminMitraPage(),
    AdminOrderPage(),
    AdminProfilPage(),
  ];

  final List<String> _titles = ['Kelola Mitra', 'Daftar Order', 'Profil Admin'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 70,
        elevation: 6,
        backgroundColor: Colors.white,
        indicatorColor: Colors.indigo.shade100,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group, color: Colors.indigo),
            label: 'Mitra',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.indigo),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.indigo),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
