import 'package:flutter/material.dart';
import 'user_layanan_order.dart';
import 'user_histori_order.dart';
import 'user_profile.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    PilihLayananPage(),
    UserHistoriOrderPage(),
    UserProfilPage(),
  ];

  final List<String> _titles = [
    'Pilih Layanan',
    'Riwayat Order',
    'Profil Pengguna',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
      automaticallyImplyLeading: false, // ← ini menghilangkan panah back
      title: Text(
        _titles[_currentIndex],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 72,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_repair_service_outlined),
            selectedIcon: Icon(Icons.home_repair_service, color: Colors.blue),
            label: 'Layanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Colors.blue),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.blue),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
