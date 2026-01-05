import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HistoriOrderPage extends StatefulWidget {
  const HistoriOrderPage({super.key});

  @override
  State<HistoriOrderPage> createState() => _HistoriOrderPageState();
}

class _HistoriOrderPageState extends State<HistoriOrderPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? mitraId;
  String selectedKategori = 'Semua';

  final List<String> kategoriList = [
    'Semua',
    'Listrik',
    'AC',
    'Pipa / Plumbing',
    'Bangunan / Renovasi',
    'Tukang Kebun',
    'Bersih-Bersih Rumah',
    'Cuci Piring / Dapur',
    'Setrika & Laundry',
    'Baby Sitter',
    'Pengasuh Lansia',
    'Asisten Rumah Tangga',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMitraId();
  }

  Future<void> fetchMitraId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() => mitraId = uid);
    }
  }

  Stream<QuerySnapshot> getOrderStream(List<String> statusList) {
    if (mitraId == null || statusList.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('mitra_id', isEqualTo: mitraId)
        .where('status', whereIn: statusList)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  List<DocumentSnapshot> applyKategoriFilter(
      List<DocumentSnapshot> docs, String? kategori) {
    if (kategori == null || kategori == 'Semua') return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['kategori'] == kategori;
    }).toList();
  }

  IconData getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'Listrik':
        return LucideIcons.zap;
      case 'AC':
        return LucideIcons.wind;
      case 'Pipa / Plumbing':
        return LucideIcons.pipette;
      case 'Bangunan / Renovasi':
        return LucideIcons.hammer;
      case 'Tukang Kebun':
        return LucideIcons.leaf;
      case 'Bersih-Bersih Rumah':
        return LucideIcons.brush;
      case 'Cuci Piring / Dapur':
        return LucideIcons.utensils;
      case 'Setrika & Laundry':
        return LucideIcons.shirt;
      case 'Baby Sitter':
        return LucideIcons.baby;
      case 'Pengasuh Lansia':
        return LucideIcons.heartHandshake;
      case 'Asisten Rumah Tangga':
        return LucideIcons.home;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  Widget buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'diproses':
        color = Colors.blue;
        label = 'Diproses';
        break;
      case 'sedang_dikerjakan':
        color = Colors.orange;
        label = 'Sedang Dikerjakan';
        break;
      case 'selesai':
        color = Colors.green;
        label = 'Selesai';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildOrderList(List<String> statusList) {
    return StreamBuilder<QuerySnapshot>(
      stream: getOrderStream(statusList),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Terjadi kesalahan saat mengambil data.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = applyKategoriFilter(docs, selectedKategori);

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('Tidak ada histori order.'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final kategori = data['kategori'] ?? '-';
            final alamat = data['alamat'] ?? '-';
            final status = data['status'] ?? '-';

            return InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/order_detail',
                  arguments: {'orderId': doc.id},
                );
              },
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(getKategoriIcon(kategori),
                          size: 32, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kategori,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alamat,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      buildStatusBadge(status),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildKategoriFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 8),
          child: Text("Filter Kategori",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: kategoriList.map((kategori) {
              final isSelected = selectedKategori == kategori;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getKategoriIcon(kategori),
                          size: 16,
                          color: isSelected ? Colors.white : Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        kategori,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedKategori = kategori),
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color:
                            isSelected ? Colors.blue : Colors.blue.shade100),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return mitraId == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Tab aktif & selesai
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Aktif'),
                  Tab(text: 'Selesai'),
                ],
              ),
              buildKategoriFilterChips(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildOrderList(['diproses', 'sedang_dikerjakan']),
                    buildOrderList(['selesai']),
                  ],
                ),
              ),
            ],
          );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
