import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MitraOrderPage extends StatefulWidget {
  const MitraOrderPage({super.key});

  @override
  State<MitraOrderPage> createState() => _MitraOrderPageState();
}

class _MitraOrderPageState extends State<MitraOrderPage> {
  List<String> keahlianMitra = [];
  String? mitraId;
  bool isLoading = true;

  final Map<String, IconData> kategoriIcons = {
    'Listrik': LucideIcons.zap,
    'AC': LucideIcons.wind,
    'Pipa / Plumbing': LucideIcons.pipette,
    'Bangunan / Renovasi': LucideIcons.hammer,
    'Tukang Kebun': LucideIcons.leaf,
    'Bersih-Bersih Rumah': LucideIcons.brush,
    'Cuci Piring / Dapur': LucideIcons.utensils,
    'Setrika & Laundry': LucideIcons.shirt,
  };

  @override
  void initState() {
    super.initState();
    getMitraData();
  }

  Future<void> getMitraData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('mitras')
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      keahlianMitra = List<String>.from(data['keahlian'] ?? []);
      mitraId = uid;
    }

    setState(() => isLoading = false);
  }

  Stream<QuerySnapshot> getOrderStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'menunggu')
        .snapshots();
  }

  bool cocokDenganKeahlian(Map<String, dynamic> dataOrder) {
    final kategori = dataOrder['kategori'];
    return kategori != null && keahlianMitra.contains(kategori);
  }

  String formatTanggal(dynamic tanggal) {
    if (tanggal == null) return '-';
    if (tanggal is Timestamp) {
      final d = tanggal.toDate();
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }
    if (tanggal is String && tanggal.length >= 10) {
      return tanggal.substring(0, 10);
    }
    return '-';
  }

  void tampilkanDetailOrder(String orderId, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Detail Order',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                buildInfoCard(Icons.category, 'Kategori', order['kategori']),
                buildInfoCard(Icons.location_on, 'Alamat', order['alamat']),
                buildInfoCard(
                  Icons.schedule,
                  'Tanggal',
                  formatTanggal(order['tanggal_order']),
                ),
                buildInfoCard(Icons.access_time, 'Waktu', order['waktu_order']),
                buildInfoCard(
                  Icons.description,
                  'Deskripsi',
                  order['deskripsi'],
                ),

                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (mitraId == null) return;

                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .update({
                            'status': 'diproses',
                            'mitra_id': mitraId,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      if (!mounted) return;

                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/detail_mitra',
                        arguments: {'orderId': orderId},
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Ambil Order"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String label, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: getOrderStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredOrders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return cocokDenganKeahlian(data);
                }).toList();

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Text("Belum ada order yang cocok"),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final doc = filteredOrders[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          kategoriIcons[data['kategori']] ?? Icons.work,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      title: Text(data['kategori'] ?? '-'),
                      subtitle: Text(data['alamat'] ?? '-'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => tampilkanDetailOrder(doc.id, data),
                    );
                  },
                );
              },
            ),
    );
  }
}
