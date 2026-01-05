import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<User?> register(String email, String password, String role) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final userCred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCred.user!.uid;

    if (role == 'user') {
      await firestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (role == 'mitra') {
      await firestore.collection('calon_mitras').doc(uid).set({
        'email': email,
        'role': 'mitra',
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCred.user;
  }

  void _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnackbar("Mohon isi semua kolom.");
      return;
    }

    if (pass.length < 6) {
      _showSnackbar("Password minimal 6 karakter.");
      return;
    }

    if (pass != confirm) {
      _showSnackbar("Konfirmasi password tidak cocok.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await register(email, pass, _selectedRole);
      if (user != null) {
        if (_selectedRole == 'mitra') {
          Navigator.pushReplacementNamed(context, '/form_mitra');
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showSnackbar("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                    "Daftar Akun",
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Konfirmasi Password",
                      hintText: "Ulangi Password",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: ['user', 'mitra'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                    },
                    decoration: InputDecoration(
                      labelText: "Pilih Role",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sudah punya akun? ",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Kembali ke halaman login
                          },
                          child: Text(
                            "Masuk",
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
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF639CD9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Daftar",
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
