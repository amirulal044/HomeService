import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminPendapatanPage extends StatefulWidget {
  const AdminPendapatanPage({super.key});

  @override
  State<AdminPendapatanPage> createState() => _AdminPendapatanPageState();
}

class _AdminPendapatanPageState extends State<AdminPendapatanPage> {
  // Variabel untuk menyimpan stream agar tidak rebuild berulang
  late Stream<QuerySnapshot> _streamTransaksi;

  @override
  void initState() {
    super.initState();
    // Inisialisasi stream hanya SEKALI saat halaman dibuka
    _streamTransaksi = FirebaseFirestore.instance
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Pendapatan Perusahaan"),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamTransaksi, // Gunakan variabel stream yang stabil
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // HITUNG TOTAL (Tetap di dalam builder agar angkanya real-time)
          double totalRevenue = 0;
          double totalAdminFees = 0;
          double totalCommission = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            double admin = (data['biaya_admin'] ?? 0).toDouble();
            double comm = (data['potongan_aplikasi'] ?? 0).toDouble();

            totalAdminFees += admin;
            totalCommission += comm;
          }
          totalRevenue = totalAdminFees + totalCommission;

          return Column(
            children: [
              _buildHeaderCard(totalRevenue, totalCommission, totalAdminFees),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.history,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Log Transaksi Masuk",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text("Belum ada data transaksi"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          // Gunakan key agar Flutter tahu widget mana yang berubah (Optimasi Rendering)
                          return _buildAdminTransactionItem(
                            data,
                            Key(docs[index].id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // WIDGET HEADER (Sama seperti sebelumnya)
  Widget _buildHeaderCard(double total, double komisi, double admin) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Total Pendapatan Bersih",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "Rp ${NumberFormat('#,###').format(total)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat("Total Komisi", komisi),
              Container(width: 1, height: 40, color: Colors.white24),
              _miniStat("Total Biaya Admin", admin),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "Rp ${NumberFormat.compact().format(val)}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // WIDGET ITEM (Ditambahkan Parameter Key)
  Widget _buildAdminTransactionItem(Map<String, dynamic> data, Key key) {
    final double omzetMitra = (data['nominal_kotor'] ?? 0).toDouble();
    final double adminFee = (data['biaya_admin'] ?? 0).toDouble();
    final double appFee = (data['potongan_aplikasi'] ?? 0).toDouble();
    final double mitraNet = (data['pendapatan_bersih'] ?? 0).toDouble();
    final double myIncome = adminFee + appFee;
    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
    final String orderIdShort = (data['order_id'] ?? '---')
        .toString()
        .substring(0, 6);

    return Card(
      key: key, // Menggunakan Key unik
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.arrowUpRight, color: Colors.indigo.shade700),
        ),
        title: Text(
          "Order #$orderIdShort",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          timestamp != null
              ? DateFormat('dd MMM, HH:mm').format(timestamp)
              : '-',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          "+ ${NumberFormat('#,###').format(myIncome)}",
          style: TextStyle(
            color: Colors.indigo.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                _rowDetail("Total Transaksi Order", omzetMitra),
                const Divider(),
                _rowDetail("Pendapatan Mitra", mitraNet, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  "Rincian Pemasukan Admin:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                _rowDetail("Komisi Aplikasi (10%)", appFee, isBold: true),
                _rowDetail("Biaya Admin", adminFee, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDetail(
    String label,
    double val, {
    Color color = Colors.black,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          Text(
            "Rp ${NumberFormat('#,###').format(val)}",
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
