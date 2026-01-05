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

  final kategoriIcons = {
    'Listrik': LucideIcons.zap,
    'AC': LucideIcons.wind,
    'Pipa / Plumbing': LucideIcons.pipette,
    'Bangunan / Renovasi': LucideIcons.hammer,
    'Tukang Kebun': LucideIcons.leaf,
    'Bersih-Bersih Rumah': LucideIcons.brush,
    'Cuci Piring / Dapur': LucideIcons.utensils,
    'Setrika & Laundry': LucideIcons.shirt,
    'Baby Sitter': LucideIcons.baby,
    'Pengasuh Lansia': LucideIcons.heartHandshake,
    'Asisten Rumah Tangga': LucideIcons.home,
    'Lainnya': LucideIcons.moreHorizontal,
  };

  @override
  void initState() {
    super.initState();
    getMitraData();
  }

  Future<void> getMitraData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('mitras').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        mitraId = uid;
        keahlianMitra = List<String>.from(data['keahlian'] ?? []);
      });
    }
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
              // drag indicator
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

              // Info Cards
              buildInfoCard(Icons.category, 'Kategori Layanan', order['kategori']),
              buildInfoCard(Icons.location_on, 'Alamat Lengkap', order['alamat']),
              buildInfoCard(Icons.schedule, 'Tanggal Order', order['tanggal_order']?.substring(0, 10)),
              buildInfoCard(Icons.access_time, 'Waktu Order', order['waktu_order']),
              buildInfoCard(Icons.description, 'Deskripsi', order['deskripsi']),

              const SizedBox(height: 16),
              if (order['foto_kondisi']?['url'] != null) ...[
                Text(
                  'Foto Kondisi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    order['foto_kondisi']['url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],

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

                    if (context.mounted) {
                      Navigator.pop(context); // tutup bottom sheet
                      Navigator.pushNamed(context, '/order_detail', arguments: {
                        'orderId': orderId,
                        'orderData': order,
                      });
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Ambil Order"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ),
  );
}

Widget buildInfoCard(IconData icon, String label, String? value) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
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
                value ?? '-',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
    if (keahlianMitra.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,

      body: StreamBuilder<QuerySnapshot>(
        stream: getOrderStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final filteredOrders = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return cocokDenganKeahlian(data);
          }).toList();

          if (filteredOrders.isEmpty) {
            return const Center(child: Text("Belum ada order yang cocok."));
          }

          return ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final doc = filteredOrders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              final kategori = data['kategori'] ?? 'Layanan';
              final alamat = data['alamat'] ?? '-';
              final tanggal = data['tanggal_order']?.substring(0, 10) ?? '-';
              final waktu = data['waktu_order'] ?? '-';
              final icon = kategoriIcons[kategori] ?? Icons.work;

              return GestureDetector(
                onTap: () => tampilkanDetailOrder(orderId, data),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(icon, color: Colors.blue.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kategori,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alamat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$tanggal • $waktu",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
