import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailC.dispose();
    passwordC.dispose();
    super.dispose();
  }

  void showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> login() async {
    if (emailC.text.isEmpty || passwordC.text.isEmpty) {
      showSnackbar("Isi semua field terlebih dahulu.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailC.text.trim(),
        password: passwordC.text.trim(),
      );

      final uid = userCredential.user!.uid;

      final adminDoc = await firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        showSnackbar("Login sebagai Admin");
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }

      final mitraDoc = await firestore.collection('mitras').doc(uid).get();
      if (mitraDoc.exists) {
        showSnackbar("Login sebagai Mitra");
        Navigator.pushReplacementNamed(context, '/dashboard_mitra');
        return;
      }

      final calonMitraDoc = await firestore.collection('calon_mitras').doc(uid).get();
      if (calonMitraDoc.exists) {
        final status = calonMitraDoc.data()?['status'] ?? 'menunggu';
        if (status == 'disetujui') {
          showSnackbar("Mitra disetujui, masuk ke dashboard mitra");
          Navigator.pushReplacementNamed(context, '/dashboard_mitra');
        } else {
          showSnackbar("Akun mitra Anda belum disetujui.");
          Navigator.pushReplacementNamed(context, '/menunggu');
        }
        return;
      }

      final userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        showSnackbar("Login sebagai User");
        Navigator.pushReplacementNamed(context, '/dashboard_user');
        return;
      }

      showSnackbar("Akun tidak ditemukan di sistem.");
    } on FirebaseAuthException catch (e) {
      showSnackbar(e.message ?? 'Gagal login');
    } catch (e) {
      showSnackbar("Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF639CD9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Animate(
            effects: const [FadeEffect(duration: Duration(milliseconds: 600)), SlideEffect()],
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo_home_service.png',
                    width: 220,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Masuk",
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailC,
                    decoration: InputDecoration(
                      labelText: 'Masukan Email',
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordC,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Masukan Password',
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Belum punya akun ? ",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          "Daftar",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF639CD9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Masuk",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
