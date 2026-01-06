import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'admin_pendapatan_page.dart'; // Pastikan file ini ada (dari diskusi sebelumnya)

class AdminProfilPage extends StatelessWidget {
  const AdminProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Silakan Login Kembali")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<DocumentSnapshot>(
        // Stream Profil Admin
        stream: FirebaseFirestore.instance
            .collection('admins')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerProfile();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data admin tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final String nama = data['nama'] ?? 'Admin';
          final String email = data['email'] ?? '-';

          // Admin biasanya tidak punya foto diri di database, kita pakai inisial/icon
          // Tapi jika ada field foto, bisa ditambahkan logic-nya.

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER PROFIL
                _buildHeader(nama, email),

                // 2. KARTU PENDAPATAN PERUSAHAAN (FLOATING)
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildRevenueCard(
                          context,
                        ), // Widget Khusus Hitung Pendapatan
                        const SizedBox(height: 20),

                        // 3. INFORMASI PRIBADI
                        _buildSectionTitle("Informasi Akun"),
                        _buildInfoCard(data),

                        const SizedBox(height: 30),

                        // 4. LOGOUT
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

  Widget _buildHeader(String nama, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade800,
            Colors.indigo.shade500,
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
              child: Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: Colors.indigo.shade500,
              ),
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
              color: Colors.indigo.shade100,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Administrator",
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET PENDAPATAN (STREAM TERPISAH KE WALLET_TRANSACTIONS)
  Widget _buildRevenueCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Mengambil SEMUA transaksi untuk menghitung total pendapatan perusahaan
      stream: FirebaseFirestore.instance
          .collection('wallet_transactions')
          .snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final t = doc.data() as Map<String, dynamic>;
            // Rumus Pendapatan Perusahaan: Biaya Admin + Potongan Aplikasi
            totalRevenue +=
                ((t['biaya_admin'] ?? 0) + (t['potongan_aplikasi'] ?? 0))
                    .toDouble();
          }
        }

        bool isLoading = snapshot.connectionState == ConnectionState.waiting;

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
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.barChart3,
                          color: Colors.indigo.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Pendapatan Perusahaan",
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.verified, color: Colors.indigo, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 30,
                        width: 150,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Rp ${NumberFormat('#,###').format(totalRevenue)}",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigasi ke AdminPendapatanPage (Detail Laporan)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPendapatanPage(),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.fileText, size: 16),
                  label: const Text("Lihat Laporan Keuangan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo.shade700,
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
      },
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
          _buildTile(LucideIcons.user, "Nama Lengkap", data['nama'] ?? '-'),
          const Divider(height: 1, indent: 60),
          _buildTile(LucideIcons.mail, "Email", data['email'] ?? '-'),
          const Divider(height: 1, indent: 60),
          _buildTile(LucideIcons.phone, "No. Telepon", data['telepon'] ?? '-'),
          const Divider(height: 1, indent: 60),
          _buildTile(
            LucideIcons.building,
            "Divisi",
            data['divisi'] ?? 'Head Office',
          ),
        ],
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
              content: const Text('Yakin ingin keluar akun admin?'),
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
