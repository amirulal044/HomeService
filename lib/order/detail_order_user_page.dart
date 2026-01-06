import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_detail_widgets.dart'; // Pastikan file ini tetap ada

class DetailOrderUserPage extends StatefulWidget {
  final String orderId;
  const DetailOrderUserPage({super.key, required this.orderId});

  @override
  State<DetailOrderUserPage> createState() => _DetailOrderUserPageState();
}

class _DetailOrderUserPageState extends State<DetailOrderUserPage> {
  // --- [BAGIAN LOGIC: Approval, Rincian, Pembayaran] ---
  // (Logic ini tetap sama, hanya dirapikan pemanggilannya)

  void _showApprovalDialog(BuildContext context, Map revisiData) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Persetujuan Biaya",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...revisiData['items']
                        .map<Widget>(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item['nama']} (x${item['qty']})",
                                  ),
                                ),
                                Text(
                                  "Rp ${NumberFormat('#,###').format(item['harga'] * item['qty'])}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
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
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
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
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(widget.orderId)
                          .update({
                            'revisi_biaya.status': 'approved',
                            'total_estimasi': revisiData['total_akhir'],
                            'active_items': revisiData['items'],
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

  void _tampilRincianBiayaSaatIni(Map<String, dynamic> data) {
    List<Map<String, dynamic>> itemsActive = [];
    if (data['active_items'] != null &&
        (data['active_items'] as List).isNotEmpty) {
      itemsActive = List<Map<String, dynamic>>.from(data['active_items']);
    } else if (data['revisi_biaya'] != null &&
        data['revisi_biaya']['status'] == 'approved') {
      itemsActive = List<Map<String, dynamic>>.from(
        data['revisi_biaya']['items'],
      );
    } else {
      itemsActive = [
        {
          'nama': 'Layanan Utama (${data['kategori']})',
          'harga': data['harga_dasar'] ?? 0,
          'qty': 1,
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
                    final sub = (item['harga'] ?? 0) * (item['qty'] ?? 1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item['nama']} (x${item['qty']})"),
                          Text(
                            "Rp ${NumberFormat('#,###').format(sub)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

            // OPSI VIRTUAL ACCOUNT (UPDATE)
            ListTile(
              leading: const Icon(LucideIcons.creditCard, color: Colors.blue),
              title: const Text("Virtual Account (BCA/Mandiri)"),
              subtitle: const Text("Verifikasi Otomatis"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                _tampilkanHalamanVA(amount); // <--- PANGGIL FUNGSI BARU INI
              },
            ),
            const Divider(),

            // OPSI TUNAI (TETAP)
            ListTile(
              leading: const Icon(LucideIcons.banknote, color: Colors.green),
              title: const Text("Tunai / Cash"),
              subtitle: const Text("Bayar langsung ke Mitra"),
              trailing: const Icon(Icons.chevron_right),
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

  // ===========================================================================
  // FITUR: SIMULASI PAYMENT GATEWAY (VA) - UI/UX FIX
  // ===========================================================================
  void _tampilkanHalamanVA(double amount) {
    String vaNumber = "8800 0812 3456 7890";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen
      backgroundColor:
          Colors.transparent, // Transparan agar rounded corner terlihat
      builder: (ctx) => Scaffold(
        // [FIX] 1. Bungkus dengan Scaffold agar SnackBar muncul di atas sheet
        backgroundColor: Colors.transparent,
        body: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          // builder ini menyediakan context baru (sheetContext)
          builder: (sheetContext, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // HEADER: Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // KONTEN UTAMA
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 1. HEADER BANK
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "BCA",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "BCA Virtual Account",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. TOTAL TAGIHAN & TIMER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Tagihan",
                            style: TextStyle(color: Colors.grey),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.timer, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                "23:59:45",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Rp ${NumberFormat('#,###').format(amount)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),

                      // 3. NOMOR VA (DENGAN FIX SNACKBAR)
                      const Text(
                        "Nomor Virtual Account",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vaNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: vaNumber),
                                );

                                // [FIX] 2. Gunakan sheetContext agar muncul di dalam modal
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 10),
                                        Text("Nomor VA Disalin!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior
                                        .floating, // Mengambang cantik
                                    margin: const EdgeInsets.all(20),
                                    duration: const Duration(seconds: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Salin",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 4. CARA PEMBAYARAN
                      const Text(
                        "Cara Pembayaran",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCaraBayarItem(
                        "ATM BCA",
                        "Masukkan kartu ATM dan PIN BCA Anda.\nPilih menu Transaksi Lainnya > Transfer > ke Rekening BCA Virtual Account.",
                      ),
                      _buildCaraBayarItem(
                        "m-BCA (BCA Mobile)",
                        "Buka aplikasi BCA Mobile.\nPilih menu m-Transfer > BCA Virtual Account.\nMasukkan nomor VA di atas.",
                      ),
                      _buildCaraBayarItem(
                        "KlikBCA",
                        "Login ke KlikBCA.\nPilih menu Transfer Dana > Transfer ke BCA Virtual Account.",
                      ),
                    ],
                  ),
                ),

                // 5. TOMBOL AKSI BAWAH
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      SizedBox(
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
                          onPressed: () {
                            Navigator.pop(ctx);
                            _prosesSimulasiBayarServer(amount);
                          },
                          child: const Text(
                            "Saya Sudah Transfer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Cek Status Nanti",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET KECIL UNTUK ACCORDION
  Widget _buildCaraBayarItem(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIKA "FAKE LOADING" AGAR TERASA REAL
  // ===========================================================================
  Future<void> _prosesSimulasiBayarServer(double amount) async {
    // 1. TAMPILKAN LOADING DIALOG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Memverifikasi pembayaran...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Mohon jangan tutup aplikasi",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    // 2. DELAY 3 DETIK (BIAR SEOLAH-OLAH CEK KE BANK)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.pop(context); // Tutup Loading

    // 3. UPDATE FIREBASE
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'payment_status':
                'pending_confirmation', // Tetap pending agar mitra cek dulu
            'payment_method': 'transfer',
            'payment_timestamp': FieldValue.serverTimestamp(),
          });

      // 4. TAMPILKAN POPUP SUKSES
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text("Pembayaran Berhasil!"),
          content: const Text(
            "Sistem telah menerima pembayaran Anda.\nNotifikasi telah dikirim ke Mitra untuk verifikasi akhir.",
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Oke, Mengerti"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
    }
  }

  void _simulateVirtualPayment(double amount) {
    // Logic Simulasi VA (Singkat)
    _kirimBuktiBayar('transfer', amount);
  }

  void _simulateCashPayment(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bayar Tunai"),
        content: const Text(
          "Serahkan uang ke mitra, lalu klik tombol di bawah.",
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

  Future<void> _kirimBuktiBayar(String method, double amount) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'payment_status': 'pending_confirmation',
          'payment_method': method,
        });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menunggu konfirmasi mitra")),
      );
  }

  // ===========================================================================
  // BAGIAN UI YANG DIROMBAK TOTAL
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
        final status = data['status'] ?? 'menunggu';
        final fotoUrl = data['foto_kondisi']?['url'];
        final paymentStatus = data['payment_status'] ?? 'unpaid';
        final totalBayar = (data['total_estimasi'] ?? 0).toDouble();
        final String? mitraId = data['mitra_id'];

        // Warna status header
        Color statusColor = Colors.blue;
        if (status == 'selesai') statusColor = Colors.green;
        if (status == 'sedang_dikerjakan') statusColor = Colors.orange;

        return Scaffold(
          backgroundColor: const Color(
            0xFFF5F7FA,
          ), // Background sedikit abu biar card pop-up
          appBar: AppBar(
            title: const Text(
              'Rincian Order',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ), // Padding bawah besar agar tidak ketutup tombol bayar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER STATUS & INFO MITRA
                _buildHeaderSection(status, statusColor, mitraId),

                const SizedBox(height: 16),

                // 2. ALERT & NOTIFIKASI (Revisi / Pembayaran)
                _buildAlertSection(data, paymentStatus),

                const SizedBox(height: 16),

                // 3. CARD BIAYA UTAMA
                _buildCostCard(data, totalBayar),

                const SizedBox(height: 16),

                // 4. DETAIL LOKASI & ORDER
                const Text(
                  "Detail Lokasi & Pekerjaan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                OrderInfoCard(data: data), // Shared Widget

                const SizedBox(height: 16),

                // 5. FOTO KONDISI
                if (fotoUrl != null) ...[
                  const Text(
                    "Foto Kondisi Awal",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      fotoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 6. STICKY BOTTOM BUTTON (Tombol Bayar)
          bottomNavigationBar:
              (paymentStatus == 'unpaid' &&
                  (status == 'sedang_dikerjakan' || status == 'selesai'))
              ? Container(
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
                  child: SafeArea(
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
                )
              : null,
        );
      },
    );
  }

  // --- WIDGET PECAHAN UI AGAR LEBIH RAPI ---

  Widget _buildHeaderSection(String status, Color color, String? mitraId) {
    return Column(
      children: [
        // Status Badge Besar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'selesai' ? Icons.check_circle : Icons.timelapse,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Kartu Mitra (Jika sudah ada)
        if (mitraId != null && status != 'menunggu')
          MitraInfoCard(mitraId: mitraId),
      ],
    );
  }

  Widget _buildAlertSection(Map<String, dynamic> data, String paymentStatus) {
    // Alert: Revisi Harga
    if (data['revisi_biaya']?['status'] == 'pending_approval') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Perubahan Biaya",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Mitra mengajukan perubahan rincian biaya. Harap konfirmasi.",
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    _showApprovalDialog(context, data['revisi_biaya']),
                child: const Text("Lihat & Konfirmasi"),
              ),
            ),
          ],
        ),
      );
    }

    // Alert: Menunggu Konfirmasi Pembayaran
    if (paymentStatus == 'pending_confirmation') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Menunggu Mitra mengonfirmasi pembayaran Anda...",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCostCard(Map<String, dynamic> data, double total) {
    bool isPaid = data['payment_status'] == 'paid';
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Tagihan",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${NumberFormat('#,###').format(total)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "LUNAS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          InkWell(
            onTap: () => _tampilRincianBiayaSaatIni(data),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Lihat Rincian Item",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// WIDGET KARTU INFO MITRA (VERSI FIX: ANTI REFRESH/KEDIP)
// ===========================================================================
class MitraInfoCard extends StatefulWidget {
  final String mitraId;

  const MitraInfoCard({super.key, required this.mitraId});

  @override
  State<MitraInfoCard> createState() => _MitraInfoCardState();
}

class _MitraInfoCardState extends State<MitraInfoCard> {
  // Variabel untuk menyimpan 'Janji' data (Future) agar tidak dipanggil ulang
  late Future<DocumentSnapshot> _futureMitraData;

  @override
  void initState() {
    super.initState();
    // 1. Ambil data HANYA saat widget pertama kali dibuat
    _futureMitraData = _fetchData();
  }

  @override
  void didUpdateWidget(covariant MitraInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 2. Cek: Jika ID Mitra berubah (misal ganti orang), baru ambil ulang.
    // Jika ID sama (cuma refresh halaman), JANGAN ambil ulang.
    if (oldWidget.mitraId != widget.mitraId) {
      _futureMitraData = _fetchData();
    }
  }

  // Fungsi helper pengambilan data
  Future<DocumentSnapshot> _fetchData() {
    // Pastikan nama collection sesuai ('mitras' atau 'users')
    return FirebaseFirestore.instance
        .collection('mitras')
        .doc(widget.mitraId)
        .get();
  }

  Future<void> _hubungiMitra(String phone) async {
    String number = phone.replaceAll(RegExp(r'\D'), '');
    if (number.startsWith('0')) number = '62${number.substring(1)}';
    final url = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _futureMitraData, // Gunakan variabel yang sudah disimpan
      builder: (context, snapshot) {
        // --- LOADING STATE (SKELETON) ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        color: const Color(0xFFEEEEEE),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        color: const Color(0xFFEEEEEE),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final String nama = data['nama'] ?? 'Mitra';
        final String foto = data['foto_diri'] ?? '';
        final String hp = data['hp'] ?? '';
        final bool isVerified = data['status'] == 'disetujui';

        final List keahlian = data['keahlian'] ?? [];
        final String spesialis = keahlian.isNotEmpty ? keahlian[0] : 'Umum';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // FOTO
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: foto.isNotEmpty
                      ? Image.network(
                          foto,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.grey),
                        )
                      : const Icon(Icons.person, color: Colors.grey, size: 30),
                ),
              ),
              const SizedBox(width: 14),

              // TEXT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nama,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Spesialis $spesialis",
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // TOMBOL WA
              if (hp.isNotEmpty)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                  ),
                  icon: const Icon(
                    LucideIcons.messageCircle,
                    color: Colors.green,
                  ),
                  tooltip: 'Chat Mitra',
                  onPressed: () => _hubungiMitra(hp),
                ),
            ],
          ),
        );
      },
    );
  }
}
