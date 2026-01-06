import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MitraPendapatanPage extends StatelessWidget {
  const MitraPendapatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Error: Belum Login")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Dompet Saya"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. CARD SALDO UTAMA
          _buildSaldoCard(user.uid),

          const SizedBox(height: 20),

          // 2. HEADER LIST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(LucideIcons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Riwayat Pemasukan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. LIST TRANSAKSI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    'wallet_transactions',
                  ) // Pastikan nama koleksi benar
                  .where('mitra_id', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // --- TAMBAHKAN BAGIAN INI AGAR ERROR MUNCUL DI TERMINAL ---
                if (snapshot.hasError) {
                  // Print ke Terminal VS Code
                  print("🔥🔥🔥 ERROR FIRESTORE: ${snapshot.error}");

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        // Pakai SelectableText biar bisa dicopy linknya dari layar HP/Web
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                // -----------------------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.wallet, size: 64, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Belum ada transaksi selesai"),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _buildTransactionItem(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mitras')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        double saldo = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          saldo = (data['saldo_dompet'] ?? 0).toDouble();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "Saldo Dompet Aktif",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                "Rp ${NumberFormat('#,###').format(saldo)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  /* Fitur Withdraw nanti */
                },
                icon: const Icon(LucideIcons.download),
                label: const Text("Tarik Dana"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data) {
    final double kotor = (data['nominal_kotor'] ?? 0).toDouble();
    final double adminApp = (data['potongan_aplikasi'] ?? 0).toDouble(); // 10%
    final double adminFee = (data['biaya_admin'] ?? 0).toDouble(); // 2000
    final double bersih = (data['pendapatan_bersih'] ?? 0).toDouble();
    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowDownLeft, color: Colors.green),
        ),
        title: Text(
          "Pemasukan Order",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          timestamp != null
              ? DateFormat('dd MMM, HH:mm').format(timestamp)
              : '-',
        ),
        trailing: Text(
          "+${NumberFormat('#,###').format(bersih)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 16,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                _row("Total Tagihan User", kotor),
                const Divider(),
                _row("Potongan Aplikasi (10%)", -adminApp, isRed: true),
                _row("Biaya Admin", -adminFee, isRed: true),
                const Divider(),
                _row("Bersih Diterima", bersih, isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    double val, {
    bool isRed = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${val < 0 ? '-' : ''} Rp ${NumberFormat('#,###').format(val.abs())}",
            style: TextStyle(
              color: isRed ? Colors.red : Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
