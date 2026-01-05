import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PilihLayananPage extends StatefulWidget {
  const PilihLayananPage({super.key});

  @override
  State<PilihLayananPage> createState() => _PilihLayananPageState();
}

class _PilihLayananPageState extends State<PilihLayananPage> {
final List<Map<String, dynamic>> _keahlianList = [
  {
    'nama': 'Listrik',
    'icon': LucideIcons.zap,
    'type': 'visit', // Biaya Kunjungan
    'price': 20000,
    'unit_name': 'x Kunjungan'
  },
  {
    'nama': 'AC (Service/Cuci)', // Saya sarankan perjelas nama layanannya
    'icon': LucideIcons.wind,
    'type': 'unit', // Per Unit
    'price': 75000,
    'unit_name': 'x Unit'
  },
  {
    'nama': 'Pipa / Plumbing',
    'icon': LucideIcons.pipette,
    'type': 'visit',
    'price': 25000,
    'unit_name': 'x Kunjungan'
  },
  {
    'nama': 'Bangunan / Renovasi',
    'icon': LucideIcons.hammer,
    'type': 'survey',
    'price': 30000, // Biaya Survey Awal
    'unit_name': 'x Survey'
  },
  {
    'nama': 'Tukang Kebun',
    'icon': LucideIcons.leaf,
    'type': 'hourly',
    'price': 40000,
    'unit_name': 'x Jam'
  },
  {
    'nama': 'Bersih-Bersih Rumah',
    'icon': LucideIcons.brush,
    'type': 'hourly',
    'price': 50000,
    'unit_name': 'x Jam'
  },
  {
    'nama': 'Cuci Piring / Dapur',
    'icon': LucideIcons.utensils,
    'type': 'hourly',
    'price': 35000,
    'unit_name': 'x Jam'
  },
  {
    'nama': 'Setrika & Laundry',
    'icon': LucideIcons.shirt,
    'type': 'hourly',
    'price': 45000,
    'unit_name': 'x Jam'
  },
];

  String _search = '';
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final filteredList = _keahlianList
        .where((item) => item['nama'].toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              onChanged: (val) => setState(() => _search = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari layanan...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.blue.shade600,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: filteredList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final layanan = filteredList[index];
                final isSelected = _selectedIndex == index;

                return Animate(
                  delay: Duration(milliseconds: 60 * index),
                  effects: const [FadeEffect(), ScaleEffect(begin: Offset(0.95, 0.95)),
                    SlideEffect(begin: Offset(0, 20))],
                  child: GestureDetector(
                  onTap: () {
                      setState(() => _selectedIndex = index);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        Navigator.pushNamed(
                          context,
                          '/form_order',
                          arguments: layanan, // <-- KIRIM FULL OBJECT (Map), jangan cuma layanan['nama']
                        );
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade500 : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100.withOpacity(isSelected ? 0.3 : 0.15),
                            offset: const Offset(0, 6),
                            blurRadius: isSelected ? 20 : 12,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              layanan['icon'],
                              size: 30,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            layanan['nama'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Profesional & terpercaya',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
