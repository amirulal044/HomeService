import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailOrderPage extends StatefulWidget {
  final String orderId;
  const DetailOrderPage({super.key, required this.orderId});

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  DocumentSnapshot? orderSnapshot;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrderData();
  }

  Future<void> loadOrderData() async {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
    setState(() {
      orderSnapshot = doc;
      isLoading = false;
    });
  }

  Future<void> updateStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusLogs': FieldValue.arrayUnion([
        {
          'status': newStatus,
          'timestamp': Timestamp.now(),
          'by': 'mitra',
        }
      ])
    });

    await loadOrderData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diperbarui ke: $newStatus')),
      );
    }
  }

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
      await updateStatus(newStatus);
    }
  }

  Future<void> bukaGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps')),
      );
    }
  }

  Widget buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'diproses':
        color = Colors.blue;
        icon = LucideIcons.clock;
        break;
      case 'sedang_dikerjakan':
        color = Colors.orange;
        icon = LucideIcons.loader2;
        break;
      case 'selesai':
        color = Colors.green;
        icon = LucideIcons.checkCircle2;
        break;
      default:
        color = Colors.grey;
        icon = LucideIcons.helpCircle;
    }

    return Chip(
      backgroundColor: color.withOpacity(0.1),
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value.isNotEmpty ? value : "-"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || orderSnapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = orderSnapshot!.data() as Map<String, dynamic>;
    final status = data['status'];
    final fotoUrl = data['foto_kondisi']?['url'];
    final lat = data['latitude'];
    final lng = data['longitude'];
    final logs = List<Map<String, dynamic>>.from(data['statusLogs'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Order', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // 🔷 Kartu Informasi Utama
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildInfoTile("Kategori", data['kategori'] ?? '', LucideIcons.briefcase),
                    buildInfoTile("Deskripsi", data['deskripsi'] ?? '', LucideIcons.alignLeft),
                    buildInfoTile("Jenis Lokasi", data['jenis_lokasi'] ?? '', LucideIcons.home),
                    buildInfoTile("Tanggal", data['tanggal_order']?.substring(0, 10) ?? '', LucideIcons.calendar),
                    buildInfoTile("Waktu", data['waktu_order'] ?? '', LucideIcons.clock),
                    buildInfoTile("Kontak", data['kontak_lain'] ?? '', LucideIcons.phone),
                    buildInfoTile("Email", data['email'] ?? '', LucideIcons.mail),

                    const SizedBox(height: 10),

                    // 🌍 Lokasi & Tombol Maps
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.mapPin, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(data['alamat'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        if (lat != null && lng != null)
                          IconButton(
                            onPressed: () => bukaGoogleMaps(lat, lng),
                            icon: const Icon(Icons.navigation, color: Colors.blue),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🖼️ Foto Kondisi
            if (fotoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(fotoUrl),
              ),
              const SizedBox(height: 12),
            ],

            // 🔖 Status Badge
            Align(alignment: Alignment.center, child: buildStatusBadge(status)),

            const SizedBox(height: 12),

            // 🧭 Tombol Aksi Status
            if (status == 'diproses')
              buildAksiButton(
                label: "Mulai Pekerjaan",
                icon: Icons.play_arrow,
                color:  Colors.blue,
                onPressed: () => konfirmasiUpdateStatus('sedang_dikerjakan'),
              ),
            if (status == 'sedang_dikerjakan')
              buildAksiButton(
                label: "Tandai Selesai",
                icon: Icons.check_circle,
                color:  Colors.green,
                onPressed: () => konfirmasiUpdateStatus('selesai'),
              ),

            const SizedBox(height: 24),

            // 📜 Riwayat Status
            if (logs.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Riwayat Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              ...logs.map((log) {
                final waktu = (log['timestamp'] as Timestamp?)?.toDate();
                final statusLog = log['status'] ?? '-';

                IconData statusIcon;
                Color iconColor;
                switch (statusLog) {
                  case 'diproses':
                    statusIcon = Icons.schedule;
                    iconColor = Colors.blue;
                    break;
                  case 'sedang_dikerjakan':
                    statusIcon = Icons.build_circle;
                    iconColor = Colors.orange;
                    break;
                  case 'selesai':
                    statusIcon = Icons.check_circle;
                    iconColor = Colors.green;
                    break;
                  default:
                    statusIcon = Icons.info;
                    iconColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.2),
                      child: Icon(statusIcon, color: iconColor),
                    ),
                    title: Text(statusLog.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      waktu != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(waktu)
                          : "(tidak diketahui)",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildAksiButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
