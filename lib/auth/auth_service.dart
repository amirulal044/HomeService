// lib/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau status login
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrasi dengan logika role-based
  Future<User?> register(String email, String password, String role) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCred.user!.uid;

    if (role == 'user') {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (role == 'mitra') {
      await _firestore.collection('calon_mitras').doc(uid).set({
        'email': email,
        'role': 'mitra',
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCred.user;
  }

  // Login
  Future<User?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Ambil UID user saat ini
  String? getCurrentUID() {
    return _auth.currentUser?.uid;
  }

  // Ambil User saat ini
  User? get currentUser => _auth.currentUser;
}
