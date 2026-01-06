import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class UserHistoriOrderPage extends StatefulWidget {
  const UserHistoriOrderPage({super.key});

  @override
  State<UserHistoriOrderPage> createState() => _UserHistoriOrderPageState();
}

class _UserHistoriOrderPageState extends State<UserHistoriOrderPage> {
  String selectedStatus = 'Semua';
  String selectedKategori = 'Semua';
  String? userId;

  final statusList = [
    'Semua',
    'menunggu',
    'diterima',
    'diproses',
    'sedang_dikerjakan',
    'selesai',
    'dibatalkan',
  ];

  final kategoriList = [
    'Semua',
    'Listrik',
    'AC',
    'Pipa / Plumbing',
    'Bangunan / Renovasi',
    'Tukang Kebun',
    'Bersih-Bersih Rumah',
    'Cuci Piring / Dapur',
    'Setrika & Laundry',
  ];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Stream<QuerySnapshot> getOrderStream() {
    Query ref = FirebaseFirestore.instance.collection('orders');

    if (userId != null) {
      ref = ref.where('user_id', isEqualTo: userId);
    }
    if (selectedStatus != 'Semua') {
      ref = ref.where('status', isEqualTo: selectedStatus);
    }
    if (selectedKategori != 'Semua') {
      ref = ref.where('kategori', isEqualTo: selectedKategori);
    }

    return ref.orderBy('updatedAt', descending: true).snapshots();
  }

  String formatTanggal(dynamic value) {
    if (value == null) return '-';
    if (value is Timestamp) {
      final d = value.toDate();
      return DateFormat('yyyy-MM-dd').format(d);
    }
    if (value is String && value.isNotEmpty) {
      return value.split('T').first;
    }
    return '-';
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'menunggu':
        return Colors.orange;
      case 'diterima':
        return Colors.blue;
      case 'diproses':
        return Colors.indigo;
      case 'sedang_dikerjakan':
        return Colors.amber.shade700;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'Listrik':
        return Icons.electrical_services;
      case 'AC':
        return Icons.ac_unit;
      case 'Pipa / Plumbing':
        return Icons.plumbing;
      case 'Bangunan / Renovasi':
        return Icons.construction;
      case 'Tukang Kebun':
        return Icons.local_florist;
      case 'Bersih-Bersih Rumah':
        return Icons.cleaning_services;
      case 'Cuci Piring / Dapur':
        return Icons.kitchen;
      case 'Setrika & Laundry':
        return Icons.local_laundry_service;
      default:
        return Icons.miscellaneous_services;
    }
  }

  double getProgress(String status) {
    switch (status) {
      case 'menunggu':
        return 0.1;
      case 'diterima':
        return 0.3;
      case 'diproses':
        return 0.5;
      case 'sedang_dikerjakan':
        return 0.75;
      case 'selesai':
        return 1.0;
      default:
        return 0.0;
    }
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOrderStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 3,
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        margin: const EdgeInsets.all(16),
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
                  return const Center(child: Text("Tidak ada histori order"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] ?? '-';
                    final kategori = data['kategori'] ?? '-';
                    final alamat = data['alamat'] ?? '-';
                    final tanggal = formatTanggal(data['tanggal_order']);
                    final waktu = data['waktu_order'] ?? '-';
                    final harga = (data['total_estimasi'] ?? 0).toDouble();

                    return Animate(
                      effects: [
                        FadeEffect(),
                        SlideEffect(begin: const Offset(0, 0.1)),
                      ],
                      delay: Duration(milliseconds: 60 * index),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/detail_user', // Panggil route khusus user
                            arguments: {
                              'orderId': docs[index].id,
                            }, // Tidak perlu isMitra lagi
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  CircleAvatar(
                                    backgroundColor: getStatusColor(
                                      status,
                                    ).withOpacity(0.15),
                                    child: Icon(
                                      getKategoriIcon(kategori),
                                      color: getStatusColor(status),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      kategori,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Rp ${NumberFormat('#,###').format(harga)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alamat,
                                style: const TextStyle(color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "$tanggal • $waktu",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: getProgress(status),
                                color: getStatusColor(status),
                                backgroundColor: Colors.grey.shade200,
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: getStatusColor(status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
