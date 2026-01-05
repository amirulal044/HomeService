import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class UserProfilPage extends StatelessWidget {
  const UserProfilPage({super.key});

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),

      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerProfile();
          }

          final data = snapshot.data;

          if (data == null) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                        child: Icon(Icons.person, size: 56, color: Colors.blue.shade700),
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
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  data['email'] ?? 'Tidak ada email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (data['role'] != null)
                  Chip(
                    label: Text(data['role']),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade800,
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline,
                          subtitle: 'Nama Lengkap',
                          title: data['nama'] ?? '-',
                          context: context,
                        ),
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.email_outlined,
                          subtitle: 'Email',
                          title: data['email'] ?? '-',
                          context: context,
                        ),
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.phone_android,
                          subtitle: 'No. Telepon',
                          title: data['telepon'] ?? '-',
                          context: context,
                        ),
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.calendar_today,
                          subtitle: 'Tanggal Lahir',
                          title: data['tanggal_lahir'] ?? '-',
                          context: context,
                        ),
                        const Divider(),
                        _buildInfoTile(
                          icon: Icons.location_on_outlined,
                          subtitle: 'Alamat',
                          title: data['alamat'] ?? '-',
                          context: context,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String subtitle,
    required String title,
    required BuildContext context,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.blue.shade700, size: 24),
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
