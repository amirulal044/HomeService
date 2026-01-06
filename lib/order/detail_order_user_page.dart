import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy Clipboard
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_detail_widgets.dart'; // Pastikan file shared widget sudah ada

class DetailOrderUserPage extends StatefulWidget {
  final String orderId;
  const DetailOrderUserPage({super.key, required this.orderId});

  @override
  State<DetailOrderUserPage> createState() => _DetailOrderUserPageState();
}

class _DetailOrderUserPageState extends State<DetailOrderUserPage> {
  // ===========================================================================
  // BAGIAN 1: LOGIC APPROVAL (MENYETUJUI / MENOLAK REVISI)
  // ===========================================================================
  void _showApprovalDialog(BuildContext context, Map revisiData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Persetujuan Biaya Tambahan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text("Mitra mengajukan rincian biaya baru:"),
            const Divider(),

            // List Item Revisi
            ...revisiData['items']
                .map<Widget>(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${item['nama']} (x${item['qty']})"),
                        Text(
                          "Rp ${NumberFormat('#,###').format(item['harga'] * item['qty'])}",
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),

            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Baru",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${NumberFormat('#,###').format(revisiData['total_akhir'])}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // TOMBOL TOLAK
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(widget.orderId)
                          .update({'revisi_biaya.status': 'rejected'});
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text("Tolak"),
                  ),
                ),
                const SizedBox(width: 10),
                // TOMBOL SETUJU
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      // Update Harga & Simpan active_items permanen
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(widget.orderId)
                          .update({
                            'revisi_biaya.status': 'approved',
                            'total_estimasi': revisiData['total_akhir'],
                            'active_items':
                                revisiData['items'], // PENTING: Simpan item
                          });
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: const Text("Setuju"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BAGIAN 2: LOGIC MELIHAT RINCIAN HARGA SAAT INI
  // ===========================================================================
  void _tampilRincianBiayaSaatIni(Map<String, dynamic> data) {
    List<Map<String, dynamic>> itemsActive = [];

    // Prioritas 1: Ambil dari active_items (yang sudah disetujui)
    if (data['active_items'] != null &&
        (data['active_items'] as List).isNotEmpty) {
      itemsActive = List<Map<String, dynamic>>.from(data['active_items']);
    }
    // Prioritas 2: Ambil dari revisi approved (backup)
    else if (data['revisi_biaya'] != null &&
        data['revisi_biaya']['status'] == 'approved') {
      itemsActive = List<Map<String, dynamic>>.from(
        data['revisi_biaya']['items'],
      );
    }
    // Prioritas 3: Harga Dasar
    else {
      itemsActive = [
        {
          'nama': 'Layanan Utama (${data['kategori']})',
          'harga': data['harga_dasar'] ?? 0,
          'qty': data['qty_order'] ?? 1,
        },
      ];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rincian Biaya Aktif",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: itemsActive.map((item) {
                    final subtotal = (item['harga'] ?? 0) * (item['qty'] ?? 1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item['nama']} (x${item['qty']})"),
                          Text(
                            "Rp ${NumberFormat('#,###').format(subtotal)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Tagihan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rp ${NumberFormat('#,###').format(data['total_estimasi'] ?? 0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BAGIAN 3: FITUR PEMBAYARAN SIMULASI (BARU)
  // ===========================================================================

  // A. Menu Pilih Metode
  void _showPaymentSelector(double amount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pilih Metode Pembayaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.creditCard, color: Colors.blue),
              title: const Text("Virtual Account (Simulasi)"),
              subtitle: const Text("Otomatis cek mutasi"),
              onTap: () {
                Navigator.pop(ctx);
                _simulateVirtualPayment(amount);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.banknote, color: Colors.green),
              title: const Text("Tunai / Cash"),
              subtitle: const Text("Bayar langsung ke Mitra"),
              onTap: () {
                Navigator.pop(ctx);
                _simulateCashPayment(amount);
              },
            ),
          ],
        ),
      ),
    );
  }

  // B. Simulasi Transfer / VA
  void _simulateVirtualPayment(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Transfer Virtual Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "No. Virtual Account",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "1234 5678 9000",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: "1234 5678 9000"),
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text("Disalin")));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Total: Rp ${NumberFormat('#,###').format(amount)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Klik tombol di bawah untuk simulasi sukses transfer:",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _kirimBuktiBayar('transfer', amount);
            },
            child: const Text("Saya Sudah Transfer"),
          ),
        ],
      ),
    );
  }

  // C. Simulasi Cash
  void _simulateCashPayment(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Bayar Tunai"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.coins, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              "Serahkan uang tunai sebesar:",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Rp ${NumberFormat('#,###').format(amount)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "ke Mitra sekarang. Klik tombol jika uang sudah diserahkan.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _kirimBuktiBayar('cash', amount);
            },
            child: const Text("Uang Sudah Diserahkan"),
          ),
        ],
      ),
    );
  }

  // D. Kirim Status ke Database
  Future<void> _kirimBuktiBayar(String method, double amount) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'payment_status': 'pending_confirmation',
          'payment_method': method,
          'payment_timestamp': FieldValue.serverTimestamp(),
        });
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Menunggu Konfirmasi"),
          content: Text(
            method == 'cash'
                ? "Notifikasi dikirim ke Mitra untuk konfirmasi penerimaan uang."
                : "Bukti transfer dikirim. Menunggu Mitra cek mutasi.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Oke"),
            ),
          ],
        ),
      );
    }
  }

  // ===========================================================================
  // BAGIAN 4: UI BUILD UTAMA
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'];
        final fotoUrl = data['foto_kondisi']?['url'];
        final paymentStatus = data['payment_status'] ?? 'unpaid';
        final totalBayar = (data['total_estimasi'] ?? 0).toDouble();

        // Cek Popup Approval otomatis
        if (data['revisi_biaya'] != null &&
            data['revisi_biaya']['status'] == 'pending_approval') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Optional: Trigger sesuatu jika perlu
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Order Saya'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // 1. KARTU HARGA & STATUS
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              OrderStatusBadge(
                                status: status,
                              ), // Menggunakan Shared Widget
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _tampilRincianBiayaSaatIni(data),
                                    child: Row(
                                      children: [
                                        Text(
                                          "Rincian Biaya",
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: Colors.blue.shade700,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Rp ${NumberFormat('#,###').format(totalBayar)}",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              // Notifikasi Revisi Pending
                              if (data['revisi_biaya']?['status'] ==
                                  'pending_approval')
                                Container(
                                  margin: const EdgeInsets.only(top: 15),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          "Mitra update biaya.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(60, 30),
                                        ),
                                        onPressed: () => _showApprovalDialog(
                                          context,
                                          data['revisi_biaya'],
                                        ),
                                        child: const Text("Cek"),
                                      ),
                                    ],
                                  ),
                                ),

                              // Status Pembayaran Pending
                              if (paymentStatus == 'pending_confirmation')
                                Container(
                                  margin: const EdgeInsets.only(top: 15),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.hourglass_top,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Menunggu konfirmasi pembayaran dari Mitra...",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Status Lunas
                              if (paymentStatus == 'paid')
                                Container(
                                  margin: const EdgeInsets.only(top: 15),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Pembayaran Lunas. Terima Kasih!",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      OrderInfoCard(data: data), // Shared Widget
                      const SizedBox(height: 12),

                      if (fotoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fotoUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // TOMBOL BAYAR (STICKY DI BAWAH)
              // Hanya muncul jika belum bayar dan order sudah berjalan/selesai
              if (paymentStatus == 'unpaid' &&
                  (status == 'sedang_dikerjakan' || status == 'selesai'))
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showPaymentSelector(totalBayar),
                      child: Text(
                        "Bayar Rp ${NumberFormat('#,###').format(totalBayar)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
