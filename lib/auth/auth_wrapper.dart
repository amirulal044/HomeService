// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/admin_home.dart';
import '../mitra/mitra_dashboard.dart';
import '../mitra/mitra_menunggu_persetujuan.dart';
import '../user/user_dashboard.dart'; // Dummy page, ganti dengan yang sesuai

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String?> checkUserRole(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final adminDoc = await firestore.collection('admins').doc(uid).get();
    if (adminDoc.exists) return 'admin';

    final mitraDoc = await firestore.collection('mitras').doc(uid).get();
    if (mitraDoc.exists) return 'mitra';

    final calonMitraDoc = await firestore.collection('calon_mitras').doc(uid).get();
    if (calonMitraDoc.exists) {
      final status = calonMitraDoc['status'] ?? 'menunggu';
      return status == 'disetujui' ? 'mitra' : 'calon_mitra';
    }

    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) return 'user';

    return null; // tidak ditemukan
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Belum login"))); // fallback, tapi tidak akan tampil
    }

    return FutureBuilder<String?>(
      future: checkUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final role = snapshot.data;
      if (role == 'admin') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda masuk sebagai Admin')),
          );
        });
        return const AdminHomePage();
      } else if (role == 'mitra') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda masuk sebagai Mitra')),
          );
        });
        return const MitraDashboardPage();
      } else if (role == 'calon_mitra') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Anda sedang menunggu persetujuan')),
          );
        });
        return const MitraMenungguPersetujuanPage();
      } else if (role == 'user') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anda masuk sebagai Pengguna')),
          );
        });
        return const UserDashboardPage();
      } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Akun tidak terdaftar dalam sistem. Silakan login ulang.")),
            );
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(); // tampilan kosong sementara saat redirect
        }

      },
    );
  }
}
