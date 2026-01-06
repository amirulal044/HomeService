import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_detail_widgets.dart'; // Pastikan file shared widget sudah ada

class DetailOrderMitraPage extends StatefulWidget {
  final String orderId;
  const DetailOrderMitraPage({super.key, required this.orderId});

  @override
  State<DetailOrderMitraPage> createState() => _DetailOrderMitraPageState();
}

class _DetailOrderMitraPageState extends State<DetailOrderMitraPage> {
  // ===========================================================================
  // BAGIAN 1: LOGIC (INPUT BIAYA, BATAL REVISI, DLL)
  // ===========================================================================

  Future<void> _tampilDialogInputBiaya(Map<String, dynamic> currentData) async {
    final _namaItemC = TextEditingController();
    final _hargaItemC = TextEditingController();
    final _qtyItemC = TextEditingController(text: '1');
    List<Map<String, dynamic>> itemsDraft = [];

    if (currentData['revisi_biaya'] != null &&
        currentData['revisi_biaya']['status'] == 'pending_approval') {
      itemsDraft = List<Map<String, dynamic>>.from(
        currentData['revisi_biaya']['items'],
      );
    } else if (currentData['active_items'] != null &&
        (currentData['active_items'] as List).isNotEmpty) {
      itemsDraft = List<Map<String, dynamic>>.from(currentData['active_items']);
    } else {
      itemsDraft.add({
        'nama': 'Layanan Utama (${currentData['kategori']})',
        'harga': currentData['harga_dasar'] ?? 0,
        'qty': currentData['qty_order'] ?? 1,
      });
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double totalDraft = 0;
            for (var i in itemsDraft) {
              totalDraft += (i['harga'] * i['qty']);
            }
            return AlertDialog(
              title: const Text("Input Rincian Biaya"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: itemsDraft.isEmpty
                            ? const Center(child: Text("Belum ada item"))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: itemsDraft.length,
                                itemBuilder: (c, i) => ListTile(
                                  dense: true,
                                  title: Text("${itemsDraft[i]['nama']}"),
                                  subtitle: Text(
                                    "${itemsDraft[i]['qty']} x Rp ${itemsDraft[i]['harga']}",
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => setStateDialog(
                                      () => itemsDraft.removeAt(i),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      TextField(
                        controller: _namaItemC,
                        decoration: const InputDecoration(
                          labelText: 'Nama Item',
                          hintText: 'Cth: Tambah Freon',
                          isDense: true,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hargaItemC,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _qtyItemC,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Tambah"),
                        onPressed: () {
                          if (_namaItemC.text.isNotEmpty &&
                              _hargaItemC.text.isNotEmpty) {
                            setStateDialog(() {
                              itemsDraft.add({
                                'nama': _namaItemC.text,
                                'harga': int.parse(_hargaItemC.text),
                                'qty': int.parse(_qtyItemC.text),
                              });
                              _namaItemC.clear();
                              _hargaItemC.clear();
                              _qtyItemC.text = '1';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total: Rp ${NumberFormat('#,###').format(totalDraft)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (itemsDraft.isEmpty) return;
                    Navigator.pop(context);
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .update({
                          'revisi_biaya': {
                            'status': 'pending_approval',
                            'items': itemsDraft,
                            'total_akhir': totalDraft,
                            'timestamp': FieldValue.serverTimestamp(),
                          },
                        });
                  },
                  child: const Text("Kirim"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _batalkanRevisi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pengajuan?"),
        content: const Text("Pengajuan akan dihapus."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'revisi_biaya': FieldValue.delete()});
    }
  }

  void _lihatDetailPending(Map<String, dynamic> revisiData) {
    List items = revisiData['items'] ?? [];
    double total = (revisiData['total_akhir'] ?? 0).toDouble();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Rincian Pengajuan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            ...items
                .map(
                  (item) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item['nama']} (x${item['qty']})"),
                      Text(
                        "Rp ${NumberFormat('#,###').format(item['harga'] * item['qty'])}",
                      ),
                    ],
                  ),
                )
                .toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${NumberFormat('#,###').format(total)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasiPembayaran(bool terima) async {
    String newStatus = terima ? 'paid' : 'unpaid';
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'payment_status': newStatus,
          if (!terima) 'payment_method': FieldValue.delete(),
        });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            terima ? "Pembayaran Diterima!" : "Pembayaran Ditolak.",
          ),
          backgroundColor: terima ? Colors.green : Colors.red,
        ),
      );
  }

  // ===========================================================================
  // LOGIKA BARU: SELESAIKAN ORDER + HITUNG PENDAPATAN MITRA
  // ===========================================================================
  Future<void> _selesaikanOrder(double totalBayar) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. RUMUS PERHITUNGAN PENDAPATAN
    double potonganPersen = 0.10; // 10%
    double nominalPotongan = totalBayar * potonganPersen;
    double biayaAdmin = 2000; // Rp 2.000
    double pendapatanBersih = totalBayar - nominalPotongan - biayaAdmin;

    try {
      // Gunakan Batch Write (Supaya semua data tersimpan bebarengan/aman)
      WriteBatch batch = firestore.batch();

      // A. Update Status Order jadi 'selesai'
      DocumentReference orderRef = firestore
          .collection('orders')
          .doc(widget.orderId);
      batch.update(orderRef, {
        'status': 'selesai',
        'updatedAt': FieldValue.serverTimestamp(),
        'statusLogs': FieldValue.arrayUnion([
          {'status': 'selesai', 'timestamp': Timestamp.now(), 'by': 'mitra'},
        ]),
      });

      // B. Catat di Riwayat Transaksi (Dompet)
      DocumentReference transRef = firestore
          .collection('wallet_transactions')
          .doc();
      batch.set(transRef, {
        'mitra_id': user.uid,
        'order_id': widget.orderId,
        'type': 'income', // Pemasukan
        'nominal_kotor': totalBayar, // Total dari User
        'potongan_aplikasi': nominalPotongan, // 10%
        'biaya_admin': biayaAdmin, // 2000
        'pendapatan_bersih': pendapatanBersih, // Yang masuk saku mitra
        'keterangan': 'Penyelesaian Order',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // C. Tambah Saldo ke Akun Mitra (Optional: Jika ada field saldo_dompet)
      DocumentReference mitraRef = firestore.collection('mitras').doc(user.uid);
      batch.update(mitraRef, {
        'saldo_dompet': FieldValue.increment(pendapatanBersih),
      });

      // EKSEKUSI SEMUA PERUBAHAN
      await batch.commit();

      // Tampilkan Info Berhasil
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Selesai! Pendapatan Rp ${NumberFormat('#,###').format(pendapatanBersih)} masuk dompet.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memproses: $e")));
    }
  }

  Future<void> konfirmasiMulaiJalan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Terima order dan mulai jalan ke lokasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final String? currentMitraId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': 'sedang_dikerjakan',
            if (currentMitraId != null) 'mitra_id': currentMitraId,
            'updatedAt': FieldValue.serverTimestamp(),
            'statusLogs': FieldValue.arrayUnion([
              {
                'status': 'sedang_dikerjakan',
                'timestamp': Timestamp.now(),
                'by': 'mitra',
              },
            ]),
          });
    }
  }

  Future<void> _hubungiUser(String phone) async {
    String number = phone.replaceAll(RegExp(r'\D'), '');
    if (number.startsWith('0')) number = '62${number.substring(1)}';
    final url = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // ===========================================================================
  // BAGIAN 2: UI (LAYOUT)
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
        final paymentStatus = data['payment_status'] ?? 'unpaid';
        final paymentMethod = data['payment_method'];
        final totalBayar = (data['total_estimasi'] ?? 0).toDouble();
        final String kontakUser = data['kontak_lain'] ?? '-';
        final String emailUser = data['email'] ?? '-';
        final String jenisLokasi = data['jenis_lokasi'] ?? '-';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('Order Masuk'),
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paymentStatus == 'pending_confirmation')
                  _buildCardKonfirmasiBayar(paymentMethod, totalBayar),
                if (data['revisi_biaya']?['status'] == 'pending_approval')
                  _buildCardPendingRevisi(data),

                Row(
                  children: [
                    Expanded(child: OrderStatusBadge(status: status)),
                    const SizedBox(width: 10),
                    if (paymentStatus == 'paid')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "LUNAS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (paymentStatus == 'unpaid')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "BELUM BAYAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCustomerCard(emailUser, kontakUser, jenisLokasi),
                const SizedBox(height: 16),
                const Text(
                  "Detail Pekerjaan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                OrderInfoCard(data: data),
                const SizedBox(height: 16),
                if (data['foto_kondisi']?['url'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['foto_kondisi']['url'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // CARD KEUANGAN
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Estimasi",
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Rp ${NumberFormat('#,###').format(totalBayar)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // TOMBOL AKSI (GESER SELESAI ADA DISINI)
                _buildActionButtons(status, data, paymentStatus, totalBayar),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS ---
  Widget _buildCustomerCard(String email, String phone, String lokasi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pelanggan",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                ),
                icon: const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.green,
                ),
                tooltip: "Hubungi User",
                onPressed: () => _hubungiUser(phone),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    phone,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    lokasi,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardKonfirmasiBayar(String? method, double amount) {
    bool isCash = method == 'cash';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCash ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCash ? Colors.green : Colors.blue),
      ),
      child: Column(
        children: [
          Text(
            isCash ? "Terima Uang Tunai?" : "Cek Transfer Masuk",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "User konfirmasi bayar Rp ${NumberFormat('#,###').format(amount)}",
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _konfirmasiPembayaran(false),
                  child: const Text("Belum"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _konfirmasiPembayaran(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCash ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Terima"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardPendingRevisi(Map<String, dynamic> data) {
    final total = data['revisi_biaya']['total_akhir'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Menunggu User Setuju",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Anda mengajukan perubahan harga. Tunggu user konfirmasi.",
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _lihatDetailPending(data['revisi_biaya']),
                  child: const Text("Lihat"),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _batalkanRevisi,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tambahkan parameter 'double totalBayar' disini 👇
  Widget _buildActionButtons(
    String status,
    Map<String, dynamic> data,
    String paymentStatus,
    double totalBayar,
  ) {
    if (status == 'diproses') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.motorcycle),
          label: const Text(
            "Terima & Mulai Jalan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: konfirmasiMulaiJalan,
        ),
      );
    }

    if (status == 'sedang_dikerjakan') {
      bool isPending = data['revisi_biaya']?['status'] == 'pending_approval';
      bool isPaid = paymentStatus == 'paid';

      return Column(
        children: [
          if (!isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(LucideIcons.receipt),
                label: const Text(
                  "Input / Revisi Biaya",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _tampilDialogInputBiaya(data),
              ),
            ),

          const SizedBox(height: 20),

          // --- SLIDE TO FINISH ---
          SlideToFinishButton(
            isPaid: isPaid,
            isPendingRevisi: isPending,
            // SEKARANG totalBayar SUDAH DIKENALI 👇
            onCompleted: () => _selesaikanOrder(totalBayar),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ===========================================================================
// [WIDGET BARU] SLIDE TO FINISH (GESER UNTUK SELESAI)
// ===========================================================================
class SlideToFinishButton extends StatefulWidget {
  final bool isPaid;
  final bool isPendingRevisi;
  final VoidCallback onCompleted;

  const SlideToFinishButton({
    super.key,
    required this.isPaid,
    required this.isPendingRevisi,
    required this.onCompleted,
  });

  @override
  State<SlideToFinishButton> createState() => _SlideToFinishButtonState();
}

class _SlideToFinishButtonState extends State<SlideToFinishButton> {
  double _dragValue = 0.0;
  double _maxWidth = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    // LOGIKA KUNCI:
    // Jika belum bayar OR ada revisi gantung -> LOCKED (Abu-abu)
    bool isLocked = !widget.isPaid || widget.isPendingRevisi;

    // Teks & Warna
    String label = "Geser untuk Selesai";
    Color bgColor = Colors.green;
    IconData icon = Icons.chevron_right;

    if (!widget.isPaid) {
      label = "Menunggu Pembayaran";
      bgColor = Colors.grey.shade400;
      icon = Icons.lock;
    } else if (widget.isPendingRevisi) {
      label = "Tunggu Revisi Disetujui";
      bgColor = Colors.orange.shade300;
      icon = Icons.lock_clock;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Stack(
            children: [
              // TEXT LABEL (Centered)
              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // DRAGGABLE HANDLE
              Positioned(
                left: _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (isLocked || _submitted)
                      return; // Tidak bisa geser kalau dikunci
                    setState(() {
                      _dragValue = (_dragValue + details.delta.dx).clamp(
                        0.0,
                        _maxWidth - 60,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (isLocked || _submitted) return;
                    if (_dragValue > _maxWidth * 0.7) {
                      // Jika geser > 70%
                      setState(() {
                        _dragValue = _maxWidth - 60;
                        _submitted = true;
                      });
                      widget.onCompleted(); // Panggil fungsi selesai
                    } else {
                      setState(
                        () => _dragValue = 0,
                      ); // Balik ke awal (snap back)
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: bgColor, size: 28),
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
