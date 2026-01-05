import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class UserHistoriOrderPage extends StatefulWidget {
  const UserHistoriOrderPage({super.key});

  @override
  State<UserHistoriOrderPage> createState() => _UserHistoriOrderPageState();
}

class _UserHistoriOrderPageState extends State<UserHistoriOrderPage> {
  String selectedStatus = 'Semua';
  String selectedKategori = 'Semua';
  String? userId;

  final List<String> statusList = [
    'Semua', 'menunggu', 'diterima', 'diproses', 'sedang_dikerjakan', 'selesai', 'dibatalkan',
  ];

  final List<String> kategoriList = [
    'Semua', 'Listrik', 'AC', 'Pipa / Plumbing', 'Bangunan / Renovasi', 'Tukang Kebun',
    'Bersih-Bersih Rumah', 'Cuci Piring / Dapur', 'Setrika & Laundry',
    'Baby Sitter', 'Pengasuh Lansia', 'Asisten Rumah Tangga', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Stream<QuerySnapshot> getOrderStream() {
    Query ref = FirebaseFirestore.instance.collection('orders');
    if (userId != null) ref = ref.where('user_id', isEqualTo: userId);
    if (selectedStatus != 'Semua') ref = ref.where('status', isEqualTo: selectedStatus);
    if (selectedKategori != 'Semua') ref = ref.where('kategori', isEqualTo: selectedKategori);
    return ref.orderBy('updatedAt', descending: true).snapshots();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'menunggu': return Colors.orange;
      case 'diterima': return Colors.blue;
      case 'diproses': return Colors.indigo;
      case 'sedang_dikerjakan': return Colors.amber.shade700;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status) {
      case 'menunggu': return Icons.hourglass_empty_rounded;
      case 'diterima': return Icons.check_circle_outline;
      case 'diproses': return Icons.build_circle_outlined;
      case 'sedang_dikerjakan': return Icons.handyman;
      case 'selesai': return Icons.verified_rounded;
      case 'dibatalkan': return Icons.cancel_rounded;
      default: return Icons.info_outline;
    }
  }

  IconData getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'Listrik': return Icons.electrical_services;
      case 'AC': return Icons.ac_unit;
      case 'Pipa / Plumbing': return Icons.plumbing;
      case 'Bangunan / Renovasi': return Icons.construction;
      case 'Tukang Kebun': return Icons.local_florist;
      case 'Bersih-Bersih Rumah': return Icons.cleaning_services;
      case 'Cuci Piring / Dapur': return Icons.kitchen;
      case 'Setrika & Laundry': return Icons.local_laundry_service;
      case 'Baby Sitter': return Icons.child_friendly;
      case 'Pengasuh Lansia': return Icons.elderly;
      case 'Asisten Rumah Tangga': return Icons.home_filled;
      default: return Icons.miscellaneous_services;
    }
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'menunggu': return 0.1;
      case 'diterima': return 0.3;
      case 'diproses': return 0.5;
      case 'sedang_dikerjakan': return 0.75;
      case 'selesai': return 1.0;
      default: return 0.0;
    }
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 28),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade900)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blue.shade500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Filter Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: kategoriList.map((kategori) {
                          final isSelected = selectedKategori == kategori;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(getKategoriIcon(kategori), size: 16, color: isSelected ? Colors.white : Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(kategori, style: TextStyle(color: isSelected ? Colors.white : Colors.blue.shade700)),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => setState(() => selectedKategori = kategori),
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isSelected ? Colors.blue : Colors.blue.shade100),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Filter Status", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: statusList.map((status) {
                          final isSelected = selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(getStatusIcon(status), size: 16, color: isSelected ? Colors.white : Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.blue.shade700)),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => setState(() => selectedStatus = status),
                              selectedColor: Colors.blue,
                              backgroundColor: Colors.blue.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isSelected ? Colors.blue : Colors.blue.shade100),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOrderStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Terjadi kesalahan.'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 3,
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.blue.shade100),
                        const SizedBox(height: 12),
                        Text('Tidak ada histori order.', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final status = data['status'] ?? '-';
                      final kategori = data['kategori'] ?? '-';
                      final alamat = data['alamat'] ?? '-';
                      final tanggal = data['tanggal_order'] ?? '';
                      final waktu = data['waktu_order'] ?? '';

                      return Animate(
                        effects: [FadeEffect(), SlideEffect(begin: const Offset(0, 0.1))],
                        delay: Duration(milliseconds: 60 * index),
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/order_detail', arguments: {'orderId': docs[index].id}),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.shade100.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(status).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(getKategoriIcon(kategori), color: getStatusColor(status), size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(kategori,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(alamat, style: TextStyle(color: Colors.blue.shade400, fontSize: 13)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade200),
                                        const SizedBox(width: 4),
                                        Text(tanggal.split('T').first, style: TextStyle(fontSize: 12, color: Colors.blue.shade300)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.blue.shade200),
                                        const SizedBox(width: 4),
                                        Text(waktu, style: TextStyle(fontSize: 12, color: Colors.blue.shade300)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: _getProgressValue(status),
                                  backgroundColor: Colors.grey.shade200,
                                  color: getStatusColor(status),
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: getStatusColor(status)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
