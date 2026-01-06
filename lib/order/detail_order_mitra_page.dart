import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'order_detail_widgets.dart'; // Pastikan file shared widget sudah ada

class DetailOrderMitraPage extends StatefulWidget {
  final String orderId;
  const DetailOrderMitraPage({super.key, required this.orderId});

  @override
  State<DetailOrderMitraPage> createState() => _DetailOrderMitraPageState();
}

class _DetailOrderMitraPageState extends State<DetailOrderMitraPage> {
  // ===========================================================================
  // BAGIAN 1: LOGIKA INPUT / EDIT BIAYA (REVISI)
  // ===========================================================================
  Future<void> _tampilDialogInputBiaya(Map<String, dynamic> currentData) async {
    final _namaItemC = TextEditingController();
    final _hargaItemC = TextEditingController();
    final _qtyItemC = TextEditingController(text: '1');

    List<Map<String, dynamic>> itemsDraft = [];

    // --- LOGIKA LOAD DATA (PENTING) ---
    // 1. Jika ada revisi PENDING -> Load data pending (Mode Edit)
    if (currentData['revisi_biaya'] != null &&
        currentData['revisi_biaya']['status'] == 'pending_approval') {
      itemsDraft = List<Map<String, dynamic>>.from(
        currentData['revisi_biaya']['items'],
      );
    }
    // 2. Jika tidak, Load data ACTIVE (Mode Tambah dari yang sudah disetujui)
    else if (currentData['active_items'] != null &&
        (currentData['active_items'] as List).isNotEmpty) {
      itemsDraft = List<Map<String, dynamic>>.from(currentData['active_items']);
    }
    // 3. Jika Order Baru -> Load Harga Dasar
    else {
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
                      // List Item
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  title: Text(
                                    "${itemsDraft[i]['nama']}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${itemsDraft[i]['qty']} x Rp ${itemsDraft[i]['harga']}",
                                    style: const TextStyle(fontSize: 12),
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
                      const Divider(),
                      // Form Input
                      TextField(
                        controller: _namaItemC,
                        decoration: const InputDecoration(
                          labelText: 'Nama Item',
                          hintText: 'Cth: Tambah Freon',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Tambah ke List"),
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
                        "Total Pengajuan: Rp ${NumberFormat('#,###').format(totalDraft)}",
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
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Revisi dikirim ke User")),
                      );
                  },
                  child: const Text("Kirim Pengajuan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // LOGIKA: HAPUS REVISI
  Future<void> _batalkanRevisi() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pengajuan?"),
        content: const Text(
          "User belum menyetujui. Pengajuan ini akan dihapus dan kembali ke harga sebelumnya.",
        ),
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
          .update({
            'revisi_biaya': FieldValue.delete(), // Hapus field
          });
    }
  }

  // LOGIKA: LIHAT DETAIL (READ ONLY)
  void _lihatDetailPending(Map<String, dynamic> revisiData) {
    List items = revisiData['items'] ?? [];
    double total = (revisiData['total_akhir'] ?? 0).toDouble();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Rincian Pengajuan Anda",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            ...items.map(
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
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Pengajuan",
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
  // BAGIAN 2: LOGIKA KONFIRMASI PEMBAYARAN
  // ===========================================================================
  Future<void> _konfirmasiPembayaran(bool terima) async {
    // Jika terima = true -> status: paid
    // Jika terima = false -> status: unpaid
    String newStatus = terima ? 'paid' : 'unpaid';

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'payment_status': newStatus,
          // Jika ditolak, hapus method agar user bisa pilih lagi
          if (!terima) 'payment_method': FieldValue.delete(),
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            terima
                ? "Pembayaran Diterima!"
                : "Pembayaran Ditolak. User diminta bayar ulang.",
          ),
          backgroundColor: terima ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // ===========================================================================
  // BAGIAN 3: UPDATE STATUS ORDER
  // ===========================================================================
  Future<void> konfirmasiUpdateStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(
          'Ubah status menjadi "${newStatus.replaceAll('_', ' ').toUpperCase()}"?',
        ),
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
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
            'statusLogs': FieldValue.arrayUnion([
              {
                'status': newStatus,
                'timestamp': Timestamp.now(),
                'by': 'mitra',
              },
            ]),
          });
    }
  }

  // ===========================================================================
  // BAGIAN 4: UI WIDGETS KHUSUS MITRA
  // ===========================================================================

  // Widget: Kartu Pending Revisi (Oranye)
  Widget _buildCardPendingRevisi(Map<String, dynamic> data) {
    final revisi = data['revisi_biaya'];
    final total = revisi['total_akhir'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.orange.shade900),
              const SizedBox(width: 8),
              Text(
                "Menunggu Persetujuan User",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Pengajuan: Rp ${NumberFormat('#,###').format(total)}",
            style: TextStyle(color: Colors.orange.shade900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _lihatDetailPending(revisi),
                  child: const Text("Detail"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tampilDialogInputBiaya(data),
                  child: const Text("Ubah"),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _batalkanRevisi,
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget: Kartu Konfirmasi Pembayaran (Hijau/Biru)
  Widget _buildCardKonfirmasiBayar(String method, double amount) {
    bool isCash = method == 'cash';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCash ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCash ? Colors.green.shade200 : Colors.blue.shade200,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCash ? LucideIcons.coins : LucideIcons.creditCard,
                size: 30,
                color: isCash ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCash ? "Terima Tunai?" : "Cek Transfer Masuk",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "User mengklaim bayar Rp ${NumberFormat('#,###').format(amount)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _konfirmasiPembayaran(false), // Tolak
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text("Belum Ada"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _konfirmasiPembayaran(true), // Terima
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCash ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Ya, Diterima"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
        final fotoUrl = data['foto_kondisi']?['url'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Masuk (Mitra)'),
            backgroundColor: Colors.blue.shade800,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 1. CEK KONFIRMASI PEMBAYARAN (PRIORITAS UTAMA)
                if (paymentStatus == 'pending_confirmation')
                  _buildCardKonfirmasiBayar(paymentMethod, totalBayar),

                // 2. KARTU UTAMA
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        OrderStatusBadge(status: status),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Estimasi",
                              style: TextStyle(color: Colors.grey),
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
                        if (paymentStatus == 'paid')
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "LUNAS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
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

                const SizedBox(height: 20),

                // 3. TOMBOL AKSI BERDASARKAN STATUS
                if (status == 'diproses')
                  ActionButton(
                    label: "Terima & Mulai",
                    icon: Icons.motorcycle,
                    color: Colors.blue.shade700,
                    onPressed: () =>
                        konfirmasiUpdateStatus('sedang_dikerjakan'),
                  ),

                if (status == 'sedang_dikerjakan') ...[
                  // CEK REVISI PENDING
                  if (data['revisi_biaya']?['status'] == 'pending_approval')
                    _buildCardPendingRevisi(data)
                  else
                    // HANYA BISA INPUT BIAYA JIKA BELUM LUNAS (Opsional logic)
                    ActionButton(
                      label: "Input / Revisi Biaya",
                      icon: LucideIcons.receipt,
                      color: Colors.orange.shade800,
                      onPressed: () => _tampilDialogInputBiaya(data),
                    ),

                  const SizedBox(height: 10),

                  // TOMBOL SELESAI
                  ActionButton(
                    label: "Selesaikan Pekerjaan",
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: () {
                      // BLOCKER: Jangan selesai jika pembayaran belum confirmed (optional)
                      if (paymentStatus == 'pending_confirmation') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Konfirmasi pembayaran dulu!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // BLOCKER: Jangan selesai jika revisi gantung
                      if (data['revisi_biaya']?['status'] ==
                          'pending_approval') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tunggu revisi disetujui user!"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      konfirmasiUpdateStatus('selesai');
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
