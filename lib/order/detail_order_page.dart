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
    required this.isMitra
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
    
    // Siapkan list draft. Jika belum ada revisi, ambil data awal.
    List<Map<String, dynamic>> itemsDraft = [];
    
    if (currentData['revisi_biaya'] == null) {
       // Masukkan harga dasar awal agar tidak hilang
       itemsDraft.add({
         'nama': 'Jasa Dasar (${currentData['kategori']})',
         'harga': currentData['harga_dasar'] ?? 0,
         'qty': currentData['qty_order'] ?? 1,
       });
    } else {
       // Jika sudah pernah revisi, load data terakhir
       itemsDraft = List<Map<String, dynamic>>.from(currentData['revisi_biaya']['items']);
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( // Agar tampilan dialog bisa refresh saat tambah item
          builder: (context, setStateDialog) {
            
            // Hitung total realtime di dialog
            double totalDraft = 0;
            for (var i in itemsDraft) { totalDraft += (i['harga'] * i['qty']); }

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
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: itemsDraft.length,
                          itemBuilder: (c, i) => ListTile(
                            dense: true,
                            title: Text("${itemsDraft[i]['nama']} (x${itemsDraft[i]['qty']})"),
                            subtitle: Text("Rp ${itemsDraft[i]['harga']}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => setStateDialog(() => itemsDraft.removeAt(i)),
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                      // Form Input
                      TextField(controller: _namaItemC, decoration: const InputDecoration(labelText: 'Item Tambahan', hintText: 'Cth: Freon / Jam Tambahan')),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _hargaItemC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga'))),
                          const SizedBox(width: 10),
                          SizedBox(width: 60, child: TextField(controller: _qtyItemC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_namaItemC.text.isNotEmpty && _hargaItemC.text.isNotEmpty) {
                            setStateDialog(() {
                              itemsDraft.add({
                                'nama': _namaItemC.text,
                                'harga': int.parse(_hargaItemC.text),
                                'qty': int.parse(_qtyItemC.text),
                              });
                              _namaItemC.clear(); _hargaItemC.clear(); _qtyItemC.text = '1';
                            });
                          }
                        },
                        child: const Text("Tambah Item"),
                      ),
                      const SizedBox(height: 10),
                      Text("Total Baru: Rp ${NumberFormat('#,###').format(totalDraft)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // UPDATE FIREBASE
                    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
                      'revisi_biaya': {
                        'status': 'pending_approval', // Status menunggu user
                        'items': itemsDraft,
                        'total_akhir': totalDraft,
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tagihan dikirim ke User")));
                  },
                  child: const Text("Kirim Tagihan"),
                )
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
  void _showApprovalDialog(BuildContext context, Map revisiData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false, // User tidak bisa tutup paksa tanpa memilih
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Persetujuan Biaya Tambahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Mitra mengajukan rincian biaya sebagai berikut:"),
            const Divider(),
            
            // Loop Items
            ...revisiData['items'].map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${item['nama']} (x${item['qty']})"),
                  Text("Rp ${NumberFormat('#,###').format(item['harga'] * item['qty'])}"),
                ],
              ),
            )).toList(),
            
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Akhir", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Rp ${NumberFormat('#,###').format(revisiData['total_akhir'])}", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                       // TOLAK: Update status jadi rejected
                       await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
                         'revisi_biaya.status': 'rejected'
                       });
                       Navigator.pop(ctx);
                    },
                    child: const Text("Tolak"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    onPressed: () async {
                       // SETUJU: Update status & Update Harga Utama
                       await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
                          'revisi_biaya.status': 'approved',
                          'total_estimasi': revisiData['total_akhir'] // TIMPA HARGA LAMA
                       });
                       Navigator.pop(ctx);
                    },
                    child: const Text("Setuju"),
                  ),
                ),
              ],
            )
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusLogs': FieldValue.arrayUnion([
          {'status': newStatus, 'timestamp': Timestamp.now(), 'by': widget.isMitra ? 'mitra' : 'user'}
        ])
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
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'];
        final fotoUrl = data['foto_kondisi']?['url'];
        final logs = List<Map<String, dynamic>>.from(data['statusLogs'] ?? []);
        
        // -----------------------------------------------------------
        // LOGIC KHUSUS USER: CEK POPUP PERSETUJUAN
        // -----------------------------------------------------------
        if (!widget.isMitra && data['revisi_biaya'] != null && data['revisi_biaya']['status'] == 'pending_approval') {
           // Gunakan callback agar tidak error saat build widget
           WidgetsBinding.instance.addPostFrameCallback((_) {
             if (ModalRoute.of(context)?.isCurrent == true) { 
                // Kita tampilkan tombol notifikasi di UI saja agar tidak spamming pop-up
             }
           });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isMitra ? 'Detail Order (Mitra)' : 'Detail Order Saya'),
            backgroundColor: widget.isMitra ? Colors.blue.shade800 : Colors.blue,
            centerTitle: true,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 1. STATUS & HARGA CARD
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Estimasi Biaya", style: TextStyle(color: Colors.grey)),
                            Text(
                              "Rp ${NumberFormat('#,###').format(data['total_estimasi'] ?? 0)}", 
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)
                            ),
                          ],
                        ),
                        
                        // NOTIFIKASI USER JIKA ADA TAGIHAN
                        if (!widget.isMitra && data['revisi_biaya']?['status'] == 'pending_approval')
                           Container(
                             margin: const EdgeInsets.only(top: 10),
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                             child: Row(
                               children: [
                                 const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                 const SizedBox(width: 8),
                                 const Expanded(child: Text("Mitra mengajukan perubahan biaya.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                 ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                   onPressed: () => _showApprovalDialog(context, data['revisi_biaya']),
                                   child: const Text("Lihat"),
                                 )
                               ],
                             ),
                           )
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
                        _buildInfoTile("Kategori", data['kategori'] ?? '', LucideIcons.briefcase),
                        _buildInfoTile("Deskripsi", data['deskripsi'] ?? '', LucideIcons.alignLeft),
                        _buildInfoTile("Tanggal", data['tanggal_order']?.substring(0, 10) ?? '', LucideIcons.calendar),
                        const Divider(),
                        Row(
                          children: [
                             const Icon(LucideIcons.mapPin, color: Colors.blue),
                             const SizedBox(width: 8),
                             Expanded(child: Text(data['alamat'] ?? '-')),
                             if (data['latitude'] != null)
                               IconButton(
                                 icon: const Icon(Icons.directions, color: Colors.blue),
                                 onPressed: () => bukaGoogleMaps(data['latitude'], data['longitude']),
                               )
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                
                // 3. FOTO
                if (fotoUrl != null) 
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(fotoUrl, height: 200, width: double.infinity, fit: BoxFit.cover)),

                const SizedBox(height: 20),

                // 4. ACTION BUTTONS (LOGIKA KHUSUS MITRA)
                if (widget.isMitra) ...[
                   if (status == 'diproses')
                      _buildButton("Terima & Mulai Jalan", Icons.motorcycle, Colors.blue.shade700, () => konfirmasiUpdateStatus('sedang_dikerjakan')),
                   
                   if (status == 'sedang_dikerjakan') ...[
                      // Tombol Input Biaya (Hanya jika tidak ada pending)
                      if (data['revisi_biaya']?['status'] != 'pending_approval')
                        _buildButton("Input / Revisi Biaya", LucideIcons.receipt, Colors.orange.shade800, () => _tampilDialogInputBiaya(data)),
                      
                      // Status Menunggu
                      if (data['revisi_biaya']?['status'] == 'pending_approval')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: const Center(child: Text("⏳ Menunggu persetujuan User...", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
                        ),

                      const SizedBox(height: 10),
                      // Tombol Selesai
                      _buildButton("Selesaikan Pekerjaan", Icons.check_circle, Colors.green, () {
                           if (data['revisi_biaya']?['status'] == 'pending_approval') {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tunggu User setuju biaya dulu!")));
                           } else {
                             konfirmasiUpdateStatus('selesai');
                           }
                      }),
                   ]
                ],

                const SizedBox(height: 20),
                
                // 5. RIWAYAT LOG
                ExpansionTile(
                  title: const Text("Riwayat Status"),
                  children: logs.map((log) {
                    final ts = (log['timestamp'] as Timestamp?)?.toDate();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 10, color: Colors.grey),
                      title: Text(log['status'].toString().toUpperCase()),
                      subtitle: Text(ts != null ? DateFormat('dd MMM HH:mm').format(ts) : '-'),
                      trailing: Text(log['by'] ?? '', style: const TextStyle(color: Colors.grey)),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  // --- Widget Helper ---
  Widget _buildButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
          Expanded(child: Text("$label: $value", style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'selesai' ? Colors.green : (status == 'sedang_dikerjakan' ? Colors.orange : Colors.blue);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      avatar: Icon(Icons.info, color: color, size: 16),
    );
  }
}