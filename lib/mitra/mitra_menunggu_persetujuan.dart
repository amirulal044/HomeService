import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';



class MitraMenungguPersetujuanPage extends StatelessWidget {
  const MitraMenungguPersetujuanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text("User tidak ditemukan"),
        ),
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('calon_mitras')
        .doc(uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        title: const Text('Status Verifikasi'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Data tidak ditemukan",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'menunggu';

          if (status == 'disetujui') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/dashboard_mitra');
            });
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 80,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pendaftaran Anda Sedang Diproses',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'STATUS: ${status.toString().toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mohon menunggu hingga admin memverifikasi data Anda.\nKami akan segera memberi informasi melalui aplikasi.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar & Login Ulang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
