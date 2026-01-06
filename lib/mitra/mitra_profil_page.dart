import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Pastikan add intl di pubspec.yaml
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'mitra_pendapatan_page.dart'; // Import halaman pendapatan yang sudah dibuat sebelumnya

class MitraProfilPage extends StatelessWidget {
  const MitraProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Silakan Login Kembali")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Background abu sangat muda
      body: StreamBuilder<DocumentSnapshot>(
        // Menggunakan Stream agar Saldo update otomatis
        stream: FirebaseFirestore.instance
            .collection('mitras')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerProfile();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data mitra tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Data Parsing
          final String nama = data['nama'] ?? 'Tanpa Nama';
          final String email = data['email'] ?? '-';
          final String foto = data['foto_diri'] ?? '';
          final double saldo = (data['saldo_dompet'] ?? 0).toDouble();
          final List keahlian = data['keahlian'] ?? [];

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER PROFIL
                _buildHeader(nama, email, foto),

                // 2. KARTU DOMPET (PENDAPATAN)
                Transform.translate(
                  offset: const Offset(0, -40), // Efek menumpuk ke atas
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildWalletCard(context, saldo),
                        const SizedBox(height: 20),

                        // 3. INFORMASI PRIBADI
                        _buildSectionTitle("Informasi Pribadi"),
                        _buildInfoCard(data),

                        const SizedBox(height: 20),

                        // 4. KEAHLIAN
                        _buildSectionTitle("Keahlian & Layanan"),
                        _buildSkillsCard(keahlian),

                        const SizedBox(height: 30),

                        // 5. LOGOUT
                        _buildLogoutButton(context),

                        const SizedBox(height: 40),
                      ],
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

  // ===========================================================================
  // WIDGETS KOMPONEN
  // ===========================================================================

  Widget _buildHeader(String nama, String email, String fotoUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        60,
        20,
        60,
      ), // Padding bawah besar untuk space kartu dompet
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade500,
          ], // Warna Khas User (Biru)
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: fotoUrl.isNotEmpty
                  ? NetworkImage(fotoUrl)
                  : null,
              child: fotoUrl.isEmpty
                  ? Icon(Icons.person, size: 50, color: Colors.blue.shade700)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.blue.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, double saldo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Total Pendapatan",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.verified_user, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Rp ${NumberFormat('#,###').format(saldo)}",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // NAVIGASI KE HALAMAN PENDAPATAN DETAIl
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MitraPendapatanPage(),
                  ),
                );
              },
              icon: const Icon(LucideIcons.history, size: 16),
              label: const Text("Lihat Riwayat & Mutasi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTile(
            LucideIcons.phone,
            "No. Telepon",
            data['hp'] ?? data['telepon'] ?? '-',
          ),
          const Divider(height: 1, indent: 60),
          _buildTile(
            LucideIcons.mapPin,
            "Alamat / Area",
            data['alamat'] ?? '-',
          ),
          const Divider(height: 1, indent: 60),
          _buildTile(
            LucideIcons.briefcase,
            "Jenis Layanan",
            data['layanan'] ?? 'Umum',
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(List keahlian) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: keahlian.isEmpty
          ? const Text(
              "- Tidak ada data keahlian -",
              style: TextStyle(color: Colors.grey),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keahlian.map<Widget>((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    skill.toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Yakin ingin keluar akun?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await FirebaseAuth.instance.signOut();
            if (context.mounted)
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
          }
        },
        icon: const Icon(LucideIcons.logOut, color: Colors.red),
        label: Text(
          "Keluar Aplikasi",
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Avatar Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(radius: 50),
          ),
          const SizedBox(height: 20),
          // Nama Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Card Besar Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                // <--- PERBAIKAN DISINI
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  20,
                ), // Masukkan ke dalam BoxDecoration
              ),
            ),
          ),
        ],
      ),
    );
  }
}
