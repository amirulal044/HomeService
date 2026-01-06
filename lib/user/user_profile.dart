import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class UserProfilPage extends StatelessWidget {
  const UserProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Silakan Login Kembali")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Latar abu muda modern
      body: StreamBuilder<DocumentSnapshot>(
        // Menggunakan Stream agar data profil selalu update jika ada perubahan
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerProfile();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Data Parsing dengan fallback
          final String nama = data['nama'] ?? 'Tanpa Nama';
          final String email = data['email'] ?? '-';
          final String fotoUrl =
              data['foto_profil'] ??
              ''; // Jika ada fitur upload foto profil user

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER PROFIL
                _buildHeader(nama, email, fotoUrl),

                // 2. CONTENT (FLOATING EFFECT)
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // 3. INFORMASI PRIBADI
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
  // WIDGETS KOMPONEN (SAMA GAYA DENGAN MITRA & ADMIN)
  // ===========================================================================

  Widget _buildHeader(String nama, String email, String fotoUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        60,
        20,
        60,
      ), // Padding bawah besar agar float masuk
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Pengguna",
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
            LucideIcons.calendar,
            "Tanggal Lahir",
            data['tanggal_lahir'] ?? '-',
          ),
          const Divider(height: 1, indent: 60),
          _buildTile(LucideIcons.mapPin, "Alamat Utama", data['alamat'] ?? '-'),
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
              content: const Text('Apakah Anda yakin ingin keluar?'),
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
