import 'package:flutter/material.dart';
import 'mitra_order_page.dart';
import 'mitra_histori.dart';
import 'mitra_profil_page.dart';

class MitraDashboardPage extends StatefulWidget {
  const MitraDashboardPage({super.key});

  @override
  State<MitraDashboardPage> createState() => _MitraDashboardPageState();
}

class _MitraDashboardPageState extends State<MitraDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    MitraOrderPage(),
    HistoriOrderPage(),
    MitraProfilPage(),
  ];

  final List<String> _titles = [
    'Order Masuk',
    'Riwayat Order',
    'Profil Mitra',
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
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Colors.blue),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Colors.blue),
            label: 'Histori',
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
