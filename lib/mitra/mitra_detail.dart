import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class MitraDetailPage extends StatelessWidget {
  const MitraDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final data = args['data'] as Map<String, dynamic>;
    final uid = args['uid'] as String;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Detail Mitra',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'setujui') {
                await setujuiMitra(context, uid);
              } else if (value == 'tolak') {
                await tolakMitra(context, uid);
              } else if (value == 'hapus') {
                await hapusMitra(context, uid);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'setujui',
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text('Setujui'),
                ),
              ),
              PopupMenuItem(
                value: 'tolak',
                child: ListTile(
                  leading: Icon(Icons.cancel_outlined, color: Colors.orange),
                  title: Text('Tolak'),
                ),
              ),
              PopupMenuItem(
                value: 'hapus',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: data['foto_diri'] != null
                        ? NetworkImage(data['foto_diri'])
                        : null,
                    backgroundColor: Colors.blue.shade100,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['nama'] ?? '-',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(data['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['status']?.toUpperCase() ?? '-',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bagian Data Personal
            buildSectionContainer([
              buildItem('Nomor KTP', data['ktp'], icon: Icons.badge),
              buildItem('Jenis Kelamin', data['gender'], icon: Icons.wc),
              buildItem('Nomor HP', data['hp'], icon: Icons.phone),
              buildItem('Alamat Lengkap', data['alamat'], icon: Icons.location_on),
            ]),

            // Bagian Keahlian dan Info Tambahan
            buildSectionContainer([
              buildKeahlianItem('Keahlian', data['keahlian']),
              buildItem('Area Layanan', data['coverage_area'], icon: Icons.map),
              buildItem('Pengalaman Kerja', data['pengalaman'], icon: Icons.work),
              buildItem('Deskripsi Diri', data['deskripsi'], icon: Icons.description),
            ]),

            // Bagian Rekening
            buildSectionContainer([
              buildItem('Nomor Rekening', data['rekening'], icon: Icons.credit_card),
              buildItem('Nama Bank', data['bank'], icon: Icons.account_balance),
              buildItem('Pemilik Rekening', data['nama_rekening'], icon: Icons.person),
            ]),

            // Tanggal Daftar
            if (data['createdAt'] != null)
              buildSectionContainer([
                buildItem('Tanggal Daftar', data['createdAt'].toDate().toString(), icon: Icons.calendar_today),
              ]),

            // Foto-foto
            if (data['foto_ktp'] != null)
              buildImageItem('Foto KTP', data['foto_ktp']),
            if (data['foto_diri'] != null)
              buildImageItem('Foto Diri', data['foto_diri']),
          ],
        ),
      ),
    );
  }

  Widget buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget buildItem(String label, dynamic value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: Icon(icon, color: Colors.blue.shade300, size: 20),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 4),
                Text(
                  value?.toString() ?? '-',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildKeahlianItem(String label, dynamic value) {
    final list = (value is List) ? value : [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.engineering, color: Colors.blue.shade300),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              list.length,
              (i) => Chip(
                label: Text(list[i]),
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                backgroundColor: Colors.blue.shade50,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageItem(String title, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              )),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'menunggu':
        return Colors.orange;
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> setujuiMitra(BuildContext context, String uid) async {
    final firestore = FirebaseFirestore.instance;
    final calonRef = firestore.collection('calon_mitras').doc(uid);
    final mitraRef = firestore.collection('mitras').doc(uid);

    final calonDoc = await calonRef.get();
    if (calonDoc.exists) {
      final data = calonDoc.data();
      data?['status'] = 'disetujui';
      await mitraRef.set(data!);
      await calonRef.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mitra berhasil disetujui')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> tolakMitra(BuildContext context, String uid) async {
    await FirebaseFirestore.instance
        .collection('calon_mitras')
        .doc(uid)
        .update({'status': 'ditolak'});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mitra ditolak')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> hapusMitra(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus mitra ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestore = FirebaseFirestore.instance;

      final calonRef = firestore.collection('calon_mitras').doc(uid);
      final calonDoc = await calonRef.get();
      if (calonDoc.exists) await calonRef.delete();

      final mitraRef = firestore.collection('mitras').doc(uid);
      final mitraDoc = await mitraRef.get();
      if (mitraDoc.exists) await mitraRef.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mitra berhasil dihapus')),
        );
        Navigator.pop(context);
      }
    }
  }
}
