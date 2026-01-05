import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class MitraProfilPage extends StatelessWidget {
  const MitraProfilPage({super.key});

  Future<Map<String, dynamic>?> getMitraData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('mitras').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getMitraData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerProfile();
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(child: Text('Data mitra tidak ditemukan.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header + Avatar
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.engineering, size: 56, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  data['nama'] ?? 'Tanpa Nama',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['email'] ?? 'Tidak ada email',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.blue.shade500),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: const Text('Mitra'),
                  backgroundColor: Colors.blue.shade100,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 24),

                // Kartu info mitra
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.person_outline, 'Nama Lengkap', data['nama'] ?? '-'),
                        const Divider(),
                        _buildInfoTile(Icons.email_outlined, 'Email', data['email'] ?? '-'),
                        const Divider(),
                        _buildInfoTile(Icons.phone, 'Telepon', data['telepon'] ?? '-'),
                        const Divider(),
                        _buildInfoTile(Icons.home_repair_service, 'Jenis Layanan', data['layanan'] ?? '-'),
                         const Divider(),
                        _buildInfoTile(Icons.location_on_outlined, 'Alamat', data['alamat'] ?? '-'),
                        const Divider(),

                       // Keahlian dalam bentuk chip (versi elegan dan presisi)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.work_outline, color: Colors.blue.shade700),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Keahlian",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['keahlian'] as List<dynamic>? ?? [])
                    .map<Widget>((e) => Chip(
                          label: Text(e),
                          backgroundColor: Colors.blue.shade100,
                          labelStyle: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
  ],
),

                        
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Tombol Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Konfirmasi Logout'),
                            content: const Text('Apakah Anda yakin ingin keluar?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String subtitle, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.blue.shade700),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }

  Widget _buildShimmerProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(radius: 50, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 20, width: 150, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 14, width: 100, color: Colors.white),
          ),
          const SizedBox(height: 30),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 200, width: double.infinity, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
