import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/login.dart';
import 'auth/register.dart';
import 'auth/auth_wrapper.dart';
import 'mitra/mitra_form_data.dart';
import 'mitra/mitra_menunggu_persetujuan.dart';
import 'mitra/mitra_dashboard.dart';
import 'admin/admin_home.dart';
import 'mitra/mitra_detail.dart';
import 'user/user_dashboard.dart';
import 'user/user_layanan_order.dart';
import 'order/order_form.dart';
import 'mitra/mitra_detail_order_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Home Service',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 🔄 Masih loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ❌ Belum login
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginPage();
          }

          // ✅ Sudah login
          return const AuthWrapper();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/form_mitra': (context) => const MitraFormDataPage(),
        '/menunggu': (context) => const MitraMenungguPersetujuanPage(),
        '/dashboard_mitra': (context) => const MitraDashboardPage(),
        '/admin': (context) => const AdminHomePage(),
        '/detail-mitra': (context) => const MitraDetailPage(),
        '/dashboard_user': (context) => const UserDashboardPage(),
        '/pilih_layanan': (context) =>  PilihLayananPage(),
        '/form_order': (context) => const FormOrderPage(),
        '/order_detail': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return DetailOrderPage(orderId: args['orderId']);
          },
      },
    );
  }
}
