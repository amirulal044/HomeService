import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  String selectedStatus = 'Semua';
  String selectedKategori = 'Semua';

  final List<String> statusList = [
    'Semua', 'menunggu', 'diterima', 'diproses',
    'sedang_dikerjakan', 'selesai', 'dibatalkan',
  ];

  final List<String> kategoriList = [
    'Semua', 'Listrik', 'AC', 'Pipa / Plumbing',
    'Bangunan / Renovasi', 'Tukang Kebun', 'Bersih-Bersih Rumah',
    'Cuci Piring / Dapur', 'Setrika & Laundry', 'Baby Sitter',
    'Pengasuh Lansia', 'Asisten Rumah Tangga', 'Lainnya'
  ];

  Stream<QuerySnapshot> getOrderStream() {
    Query ref = FirebaseFirestore.instance.collection('orders');

    if (selectedStatus != 'Semua') {
      ref = ref.where('status', isEqualTo: selectedStatus);
    }

    if (selectedKategori != 'Semua') {
      ref = ref.where('kategori', isEqualTo: selectedKategori);
    }

    ref = ref.orderBy('updatedAt', descending: true);
    return ref.snapshots();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'menunggu': return Colors.orange;
      case 'diterima': return Colors.green.shade700;
      case 'diproses': return Colors.blue;
      case 'sedang_dikerjakan': return Colors.indigo;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedKategori,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: kategoriList
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedKategori = val ?? 'Semua'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: statusList
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedStatus = val ?? 'Semua'),
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
                if (snapshot.hasError) {
                  return const Center(child: Text('Terjadi kesalahan.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('Tidak ada data order.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final kategori = data['kategori'] ?? '-';
                    final alamat = data['alamat'] ?? '-';
                    final status = data['status'] ?? '-';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.home_repair_service,
                              color: Colors.blue.shade700),
                        ),
                        title: Text(
                          kategori,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(alamat),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 10),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withOpacity(0.1),
                            border: Border.all(color: getStatusColor(status)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/order_detail',
                            arguments: {'orderId': docs[index].id},
                          );
                        },
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
