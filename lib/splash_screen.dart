import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart'; // Impor MyApp

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    // Inisialisasi Hive
    await Hive.initFlutter();
    await Hive.openBox('transactions');
    await Hive.openBox('categories');
    await Hive.openBox('accounts');

    // Simulasi waktu loading
    await Future.delayed(const Duration(seconds: 2));

    // Navigasi ke aplikasi utama
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/preloader.png'), // Ganti dengan path gambar preloader Anda
      ),
    );
  }
}