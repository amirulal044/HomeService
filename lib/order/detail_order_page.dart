import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailOrderPage extends StatefulWidget {
  final String orderId;
  final bool isMitra; // VARIABEL PENTING: Pembeda antara User dan Mitra

  const DetailOrderPage({
    super.key,
    required this.orderId,
    required this.isMitra,
  });

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  // ===========================================================================
  // BAGIAN 1: LOGIKA MITRA (INPUT BIAYA TAMBAHAN)
  // ===========================================================================
  Future<void> _tampilDialogInputBiaya(Map<String, dynamic> currentData) async {
    final _namaItemC = TextEditingController();
    final _hargaItemC = TextEditingController();
    final _qtyItemC = TextEditingController(text: '1');

    List<Map<String, dynamic>> itemsDraft = [];

    // LOGIKA LOAD DATA AWAL MITRA:

    // 1. Cek apakah ada revisi yang SEDANG PENDING (Mitra mau edit revisi yang barusan dia buat)
    if (currentData['revisi_biaya'] != null &&
        currentData['revisi_biaya']['status'] == 'pending_approval') {
      itemsDraft = List<Map<String, dynamic>>.from(
        currentData['revisi_biaya']['items'],
      );
    }
    // 2. Jika tidak ada pending, ambil dari ACTIVE ITEMS (Revisi terakhir yang disetujui user)
    else if (currentData['active_items'] != null &&
        (currentData['active_items'] as List).isNotEmpty) {
      itemsDraft = List<Map<String, dynamic>>.from(currentData['active_items']);
    }
    // 3. Jika masih kosong juga, ambil dari HARGA DASAR (Orderan masih fresh)
    else {
      itemsDraft.add({
        'nama': 'Layanan Utama (${currentData['kategori']})',
        'harga': currentData['harga_dasar'] ?? 0,
        'qty': currentData['qty_order'] ?? 1,
      });
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          // Agar tampilan dialog bisa refresh saat tambah item
          builder: (context, setStateDialog) {
            // Hitung total realtime di dialog
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
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: itemsDraft.length,
                          itemBuilder: (c, i) => ListTile(
                            dense: true,
                            title: Text(
                              "${itemsDraft[i]['nama']} (x${itemsDraft[i]['qty']})",
                            ),
                            subtitle: Text("Rp ${itemsDraft[i]['harga']}"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setStateDialog(() => itemsDraft.removeAt(i)),
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                      // Form Input
                      TextField(
                        controller: _namaItemC,
                        decoration: const InputDecoration(
                          labelText: 'Item Tambahan',
                          hintText: 'Cth: Freon / Jam Tambahan',
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
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
                        child: const Text("Tambah Item"),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total Baru: Rp ${NumberFormat('#,###').format(totalDraft)}",
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
                    Navigator.pop(context);
                    // UPDATE FIREBASE
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(widget.orderId)
                        .update({
                          'revisi_biaya': {
                            'status':
                                'pending_approval', // Status menunggu user
                            'items': itemsDraft,
                            'total_akhir': totalDraft,
                          },
                        });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tagihan dikirim ke User")),
                    );
                  },
                  child: const Text("Kirim Tagihan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // BAGIAN 2: LOGIKA USER (DIALOG APPROVAL)
  // ===========================================================================
  // ===========================================================================
  // BAGIAN 2: LOGIKA USER (DIALOG APPROVAL) - SUDAH DIPERBAIKI
  // ===========================================================================
  void _showApprovalDialog(BuildContext context, Map revisiData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // User tidak bisa tutup paksa tanpa memilih
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
            const Text("Mitra mengajukan rincian biaya sebagai berikut:"),
            const Divider(),

            // Loop Items untuk ditampilkan
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
                  "Total Akhir",
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
                // TOMBOL 1: TOLAK (REJECT)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      // LOGIKA TOLAK:
                      // Hanya update status jadi 'rejected'.
                      // Jangan ubah total_estimasi atau active_items.
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

                // TOMBOL 2: SETUJU (APPROVE)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      // LOGIKA SETUJU:
                      // 1. Update status revisi -> approved
                      // 2. Update total_estimasi -> harga baru
                      // 3. Simpan items ke field permanen 'active_items' (PENTING)

                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(widget.orderId)
                          .update({
                            'revisi_biaya.status': 'approved',
                            'total_estimasi':
                                revisiData['total_akhir'], // Update Harga Utama
                            'active_items':
                                revisiData['items'], // Simpan Item Permanen
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
  // BAGIAN 3: FITUR LIHAT RINCIAN (SELENGKAPNYA)
  // ===========================================================================
  void _tampilRincianBiayaSaatIni(Map<String, dynamic> data) {
    List<Map<String, dynamic>> itemsActive = [];

    // LOGIKA BARU YANG LEBIH STABIL:

    // 1. Cek apakah ada field 'active_items' di database (Hasil simpanan dari tombol Setuju)
    if (data['active_items'] != null &&
        (data['active_items'] as List).isNotEmpty) {
      itemsActive = List<Map<String, dynamic>>.from(data['active_items']);
    }
    // 2. Jika tidak ada active_items, cek apakah revisi_biaya statusnya approved (Backward compatibility)
    else if (data['revisi_biaya'] != null &&
        data['revisi_biaya']['status'] == 'approved' &&
        data['revisi_biaya']['items'] != null) {
      itemsActive = List<Map<String, dynamic>>.from(
        data['revisi_biaya']['items'],
      );
    }
    // 3. Jika semua kosong, berarti masih menggunakan Harga Dasar Original
    else {
      itemsActive = [
        {
          'nama': 'Layanan Utama (${data['kategori'] ?? 'Jasa'})',
          'harga': data['harga_dasar'] ?? 0,
          'qty': data['qty_order'] ?? 1,
        },
      ];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.receipt, color: Colors.blue),
                const SizedBox(width: 10),
                const Text(
                  "Rincian Biaya Aktif",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const Divider(height: 25),

            // Loop Item
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  children: itemsActive.map((item) {
                    final nama = item['nama'] ?? 'Item';
                    final harga = (item['harga'] as num?)?.toInt() ?? 0;
                    final qty = (item['qty'] as num?)?.toInt() ?? 1;
                    final subtotal = harga * qty;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (qty > 1)
                                  Text(
                                    "$qty x Rp ${NumberFormat('#,###').format(harga)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

            const Divider(height: 25),

            // Total dari Database (Selalu sinkron dengan active_items)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Akhir",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rp ${NumberFormat('#,###').format(data['total_estimasi'] ?? 0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LOGIKA UMUM: Update Status Order
  Future<void> konfirmasiUpdateStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Ubah status menjadi "$newStatus"?'),
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
                'by': widget.isMitra ? 'mitra' : 'user',
              },
            ]),
          });
    }
  }

  Future<void> bukaGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // MENGGUNAKAN STREAM BUILDER AGAR REALTIME
    // Ini menggantikan FutureBuilder lama
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
        final logs = List<Map<String, dynamic>>.from(data['statusLogs'] ?? []);

        // -----------------------------------------------------------
        // LOGIC KHUSUS USER: CEK POPUP PERSETUJUAN
        // -----------------------------------------------------------
        if (!widget.isMitra &&
            data['revisi_biaya'] != null &&
            data['revisi_biaya']['status'] == 'pending_approval') {
          // Gunakan callback agar tidak error saat build widget
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              // Kita tampilkan tombol notifikasi di UI saja agar tidak spamming pop-up
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isMitra ? 'Detail Order (Mitra)' : 'Detail Order Saya',
            ),
            backgroundColor: widget.isMitra
                ? Colors.blue.shade800
                : Colors.blue,
            centerTitle: true,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 1. STATUS & HARGA CARD
                // 1. STATUS & HARGA CARD
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: 16),

                        // --- UPDATE BAGIAN INI ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Estimasi Biaya",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                GestureDetector(
                                  onTap: () => _tampilRincianBiayaSaatIni(data),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Lihat Rincian",
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 14,
                                        color: Colors.blue.shade700,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Rp ${NumberFormat('#,###').format(data['total_estimasi'] ?? 0)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        // --- AKHIR UPDATE ---

                        // NOTIFIKASI USER JIKA ADA TAGIHAN PENDING (KODE LAMA TETAP ADA DI BAWAH SINI)
                        if (!widget.isMitra &&
                            data['revisi_biaya']?['status'] ==
                                'pending_approval')
                          Container(
                            margin: const EdgeInsets.only(
                              top: 15,
                            ), // Ubah margin dikit biar rapi
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
                                    "Mitra mengajukan perubahan biaya.",
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. INFO LOKASI & DETAIL
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          "Kategori",
                          data['kategori'] ?? '',
                          LucideIcons.briefcase,
                        ),
                        _buildInfoTile(
                          "Deskripsi",
                          data['deskripsi'] ?? '',
                          LucideIcons.alignLeft,
                        ),
                        _buildInfoTile(
                          "Tanggal",
                          data['tanggal_order']?.substring(0, 10) ?? '',
                          LucideIcons.calendar,
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(data['alamat'] ?? '-')),
                            if (data['latitude'] != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.directions,
                                  color: Colors.blue,
                                ),
                                onPressed: () => bukaGoogleMaps(
                                  data['latitude'],
                                  data['longitude'],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. FOTO
                if (fotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fotoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 20),

                // 4. ACTION BUTTONS (LOGIKA KHUSUS MITRA)
                if (widget.isMitra) ...[
                  if (status == 'diproses')
                    _buildButton(
                      "Terima & Mulai Jalan",
                      Icons.motorcycle,
                      Colors.blue.shade700,
                      () => konfirmasiUpdateStatus('sedang_dikerjakan'),
                    ),

                  if (status == 'sedang_dikerjakan') ...[
                    // Tombol Input Biaya (Hanya jika tidak ada pending)
                    if (data['revisi_biaya']?['status'] != 'pending_approval')
                      _buildButton(
                        "Input / Revisi Biaya",
                        LucideIcons.receipt,
                        Colors.orange.shade800,
                        () => _tampilDialogInputBiaya(data),
                      ),

                    // Status Menunggu
                    if (data['revisi_biaya']?['status'] == 'pending_approval')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "⏳ Menunggu persetujuan User...",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    // Tombol Selesai
                    _buildButton(
                      "Selesaikan Pekerjaan",
                      Icons.check_circle,
                      Colors.green,
                      () {
                        if (data['revisi_biaya']?['status'] ==
                            'pending_approval') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tunggu User setuju biaya dulu!"),
                            ),
                          );
                        } else {
                          konfirmasiUpdateStatus('selesai');
                        }
                      },
                    ),
                  ],
                ],

                const SizedBox(height: 20),

                // 5. RIWAYAT LOG
                ExpansionTile(
                  title: const Text("Riwayat Status"),
                  children: logs.map((log) {
                    final ts = (log['timestamp'] as Timestamp?)?.toDate();
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.circle,
                        size: 10,
                        color: Colors.grey,
                      ),
                      title: Text(log['status'].toString().toUpperCase()),
                      subtitle: Text(
                        ts != null
                            ? DateFormat('dd MMM HH:mm').format(ts)
                            : '-',
                      ),
                      trailing: Text(
                        log['by'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Widget Helper ---
  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'selesai'
        ? Colors.green
        : (status == 'sedang_dikerjakan' ? Colors.orange : Colors.blue);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      avatar: Icon(Icons.info, color: color, size: 16),
    );
  }
}
